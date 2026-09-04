# What actually broke, and how it was diagnosed

Built 2026-08-28 between two MikroTik CHRs — one on Alibaba Cloud
(`ap-southeast-5`), one on GCP (`asia-southeast2`). Both ends sit behind **1:1
NAT**: neither box has its public address on any interface.

The sibling project `cloud-chr-pfsense-ipsec-bgp` connects a CHR to a pfSense and
looks like the same problem. It is not, and three of its patterns fail here.

## 1. `my-id=address:<own public IP>` fails when RouterOS is the responder

This is what blocked IKE entirely.

The pfSense build pins `my-id` to the box's own EIP and works. Copying it here
gives, in **both** directions:

```
ipsec processing payload: ID_I
ipsec ID_I (ADDR4): 34.101.118.166        <- the ID on the wire is correct
ipsec processing payload: ID_R
ipsec ID_R (ADDR4): 8.215.24.90           <- so is this one
ipsec,error identity not found for responder: ADDR4:8.215.24.90 peer: ADDR4:34.101.118.166
ipsec reply notify: AUTHENTICATION_FAILED
```

RouterOS says it cannot find an identity whose `my-id` is `8.215.24.90` while an
identity with exactly that `my-id` is configured, enabled and not dynamic. A
responder will not match an identity pinned to an address that exists on no
local interface — and under 1:1 NAT the EIP exists nowhere.

Why the pfSense build never hit it: there, only one side was NAT'd, and the CHR
was the side that initiated. An initiator only *sends* `my-id`; nothing has to
match it. Here both ends are RouterOS, both initiate, so both must also answer
as responder — the log shows `(I)` and `(R)` alternating on each box.

**Fix:** `my-id=auto remote-id=ignore` on both ends. Peer authenticity still
rests on the PSK and on `address=<peer public>/32` in `/ip/ipsec/peer`.

Ruled out first, with evidence rather than reasoning:

| Suspect | Evidence against |
|---|---|
| PSK mismatch / base64 quoting | replaced both ends with an identical 64-char hex PSK (no `/`, `+`, `=`); symptom unchanged |
| Wrong ID values | debug log shows `ID_I` / `ID_R` on the wire exactly matching the config |
| Firewall | both ends see the peer's IKE arrive; `new ike2 SA (R)` names the peer, so peer-by-address matching succeeded |
| Corrupt identity object | removed and re-added from scratch on both ends; unchanged |
| `remote-id=auto`, then `=ignore` | error text changes (the `responder:` clause disappears) but auth still fails |

The error-text change under `remote-id` is a red herring worth naming: it proves
the setting takes effect, which makes it easy to keep tuning that field. The
fault was on the `my-id` side the whole time.

## 2. Traffic selectors must be private↔private — NAT does not rewrite them

The pfSense build pairs `local private ↔ peer PUBLIC`:

```
CHR    : policy src=<CHR_PRIV>/32 dst=<PF_PUB>/32 protocol=gre
pfSense: phase2  local=<PF_PUB>/32 remote=<CHR_PRIV>/32
```

Reproducing that here fails at phase 2:

```
ipsec create child: respond
ipsec processing payload: TS_I
ipsec processing payload: TS_R
ipsec reply notify: TS_UNACCEPTABLE
```

The policy loses its `A` (active) flag and `ph2-state=no-phase2`.

The reasoning trap: it is tempting to argue the selectors mirror *after* NAT —
Alibaba rewrites the source, so `10.151.127.250 → 34.101.118.166` arrives as
`8.215.24.90 → 10.101.16.10`, which looks like the peer's mirror image. That is
true of the packet and irrelevant to the negotiation. **The traffic-selector
payload is negotiated data inside the IKE exchange, not headers NAT touches.**
Both ends must name the same literal values.

**Fix:** each side's peering-subnet private address on both sides of the
selector, exact mirror images:

```
Ali: src=10.151.127.250/32  dst=10.101.16.10/32     protocol=gre
GCP: src=10.101.16.10/32    dst=10.151.127.250/32   protocol=gre
```

GRE `remote-address` follows the same rule: the peer's **private** peering
address. No VIP trick needed — the symmetry is free when both ends are NAT'd the
same way.

## 3. AES-CBC takes the wrong offload path: mature SAs, zero inbound

With IKE up and selectors mirrored, both SAs reach `mature` with paired SPIs and
outbound bytes climb — yet every ping across the tunnel times out.

```
/interface print stats where name~"gre"
  gre-gcp  RX-BYTE 0  TX-BYTE 120568        <- both ends. Everyone sends, nobody receives.

/ip/ipsec/statistics/print
  in-state-protocol-errors: 456             <- rises ~1 per packet the peer sent
```

Measured directly: 10 pings out of GCP raised GCP's own
`in-state-protocol-errors` by 9. So the replies **arrive** and die in the inbound
transform. Not routing, not firewall, not MTU.

The tell is in the SA flags:

```
Flags: S - SEEN-TRAFFIC; H - HW-AEAD; E - ESP
 0  HE spi=0x4F60C1CE ... auth-algorithm=sha256 enc-algorithm=aes-cbc
```

`H` = HW-AEAD on an SA whose cipher is AES-CBC + HMAC-SHA256, which is **not**
AEAD. Wrong offload path; decryption yields garbage that fails the protocol
check. Note also the missing `S` (seen-traffic) flag on the inbound SA — a
one-character signal that nothing has ever successfully decrypted.

**Fix:** a real AEAD cipher on both ends.

```
/ip ipsec proposal set [find] auth-algorithms="" enc-algorithms=aes-256-gcm
```

`auth-algorithms` must be empty — GCM carries its own integrity. Tunnel came up
on the first ping after the change: 6/6, 0% loss, 2.3 ms.

**Diagnostic worth internalising:** mature SAs plus `RX=0` means decrypt failure.
Check `in-state-protocol-errors` before touching routes or firewall rules, and
read the SA flags — `H` without a genuine AEAD cipher is the whole answer.

## 4. No static route to the peer's GRE endpoint

An earlier draft of these templates added one. It is redundant: the default route
already covers the peer's peering address, and the IPsec policy intercepts the
GRE packet on the output path regardless of which route matched — the packet
never leaves in the clear. The proven pfSense-era config has exactly **one**
static route, the VPC supernet, and so do these templates.

## 5. `network` advertises nothing unless the prefix is in the RIB

Unchanged from the pfSense project, but sharper on GCP: DHCP hands out **/32**
addresses on both NICs and gives `ether2` **no gateway at all**, so there is no
connected route covering either subnet. Without the supernet static route BGP
advertises nothing at all.

```
/ip route add dst-address=10.101.0.0/18 gateway=ether2 comment="vpc network"
```

Next-hop is the **interface**, not a gateway address — there is no gateway
address to aim at, and the GCP fabric answers ARP for on-subnet destinations.

In RouterOS 7 the advertisement itself is an **address-list** referenced by
`output.network=`; there is no `/routing/bgp/network` menu as in v6 (that path is
a syntax error on 7.23.3).

## 6. RouterOS 7 BGP syntax, verified on 7.23.3

- `/routing/bgp/connection` requires **both** `instance` and `local.role`;
  omitting either fails with `missing value(s) of argument(s)`.
- The named instance must exist before a connection can reference it.
- `router-id` belongs on the **instance**, not the template — on
  `/routing/bgp/template` it fails with `bad parameter router-id`.

## 7. `/import` reports failure on stdout and still exits 0

A shell wrapper that trusts the exit code will print "applied" over a config that
half-loaded. The first apply here failed at the `router-id` line, leaving IPsec
and GRE created and BGP absent, while the script claimed success. `apply.sh` now
greps the import output for `script error|syntax error|bad parameter|failure` and
fails loudly.

Related: the pfSense-era `apply.sh` removed `/ip/dhcp-client` during cleanup.
Doing that here would drop every interface address, the default route, and the
SSH session applying the config — both CHRs get all addressing from DHCP and the
templates do not re-add the clients.

## 8. NAT must exclude the peer supernet

Both CHRs are the internet path for their private subnet, so both need
masquerade — and both need the exclusion:

```
/ip firewall nat add chain=srcnat action=masquerade out-interface=ether1 \
    src-address=<own supernet> dst-address=!<peer supernet> \
    comment="NAT private subnet to the internet, never to the peer"
```

Without `dst-address=!`, traffic to the peer cloud gets source-NAT'd to the
router's own address, the far side replies to the router instead of the
originating host, and LAN-to-LAN dies while tunnel-address pings keep working.
That is the same class of fault as pfSense's Automatic Outbound NAT covering the
tunnel interface.

The stock Alibaba CHR image also ships a bare `chain=srcnat action=masquerade`
rule matching **everything**, tunnel traffic included. `apply.sh` removes it.

On GCP the rule is currently **inert**: `nextops-default-route` points at the
bastion NAT and matches tags `bastion,app,database,observability`, none of which
are on this instance. Correct and waiting for a route or tag to send workload
traffic here.

## 9. ~1 Mbit/s TX with unlimited RX: the licence is stale until a reboot

Symptom, after the tunnel was fully working:

```
Ali -> GCP   sender 100.5 Mbps   receiver (GCP ether1 RX) ~107 Mbps   OK
GCP -> Ali   sender   1.26 Mbps  receiver (Ali ether1 RX)  ~1.0 Mbps  BROKEN
```

Sender and receiver **agree** at ~1 Mbps and `in-state-protocol-errors` is 0 at
both ends, so nothing is lost or failing to decrypt — the sender simply never
puts more on the wire. One box decrypts at 100 Mbps and encrypts at 0.9 Mbps.

`~1 Mbit/s on TX with RX unrestricted is the exact signature of an unlicensed
CHR` — the free-tier limit applies per interface on transmit only. Both boxes
report `level: p-unlimited`, so the licence looks fine. The tell is one field:

```
chr-ali   next-renewal-at: 2099-12-02 07:00:00     TX = 100 Mbps
chr-gcp   next-renewal-at: <empty>                 TX = 1.26 Mbps
```

`/system/license/print` shows the **stored** level, not the one being enforced.
On this GCP CHR — built from a custom imported image — the licence had not been
read into the running system. **A reboot fixes it**, and `next-renewal-at` is
populated afterwards, matching the working peer:

```
GCP -> Ali  UDP  0.9 -> 93.0 Mbps
GCP -> Ali  TCP  0.9 -> 94.2 Mbps     (Ali ether1 RX confirms ~94 Mbps, 0 errors)
Ali -> GCP  TCP        98.9 Mbps
both directions at once  tx 90.2 / rx 94.8 Mbps
```

The tunnel, SAs and BGP all come back on their own after the reboot — no
reconfiguration needed.

**What this cost, and how to skip it:** every plausible in-band cause was
measured and eliminated first — per-core CPU (max 6% on one core under the
failing load), MTU (1300 did not help; 1472 DF passes inside the GCP VPC),
cipher (`aes-128-gcm` identical), packet size (600-byte identical), TCP vs UDP,
congestion ramp (`local-tx-speed=10M` still 0.9), queues (none), conntrack
flush, and the btest-generator confound (an SFTP transfer with no generator gave
the same 0.94 Mbps). The single most useful reading was `/tool/profile` showing
**total 0%** while the box "sent" 1.26 Mbps: an idle router that will not fill
the wire is rate-limiting itself, which points at licensing rather than load.

Check `next-renewal-at` on both peers before chasing anything else, especially
on a CHR built from an imported image.

### Measurement hazards that produced two false conclusions

Both were errors in method, not in the network, and both wasted a diagnostic
round:

- **`\$VAR` inside a double-quoted RouterOS command sent over SSH** reaches the
  device as a literal `$VAR` — an undefined RouterOS variable, so the password
  is empty, auth fails, and btest reports `0bps`. That is not a throughput
  figure. Write the script to a temp file with the value already substituted by
  the shell, or use single quotes.
- **Deleting the btest user from one end** and only recreating it on the other
  makes every test aimed at the deleted side report `0bps` for the same reason.

Both produced "evidence" of decrypt failures (`in-state-protocol-errors` deltas
of 306 and 857) that vanished under valid load. **Always confirm throughput at
the receiver's own interface counters**, not just the sender's report.

## 10. Alibaba ENIs drop forwarded packets until SourceDestCheck is off

Alibaba Cloud ENIs ship with `SourceDestCheck=true`, and the hypervisor drops any
packet whose source IP is not the ENI's own. A CHR acting as NAT gateway / router
/ NVA forwards packets sourced from private hosts, so every one of them is
discarded before it leaves — with nothing logged on the instance.

Disable it on **both** CHR ENIs. In Terraform, `source_dest_check = false` on
`alicloud_instance` (provider `v1.284.0+`).

GCP's equivalent is `can_ip_forward = true`, which was already set on the GCP CHR
from the start — the asymmetry is easy to miss because only one cloud makes you
ask for it under a name you would search for.

## 11. GRE in the firewall rules is symmetry, not a requirement

Both clouds whitelist GRE (protocol 47) between the two public addresses. It is
harmless and it documents intent, but it carries no traffic in this design: GRE is
the **inner** protocol, encapsulated inside ESP, and ESP itself rides UDP 4500
because both ends are behind 1:1 NAT. No bare GRE packet ever reaches the wire.

Worth stating plainly so nobody adds it expecting to fix a broken tunnel, or
removes it expecting to break a working one. The rules that actually matter are
UDP 500 and UDP 4500.

## 12. Alibaba Cloud Multi-NIC NVA Route Table Next-Hop Requirement (2026-09-04)

When deploying a Multi-NIC NVA / CHR on Alibaba Cloud across multiple vSwitches (e.g. `ether1` WAN on peering vSwitch `10.151.63.240/28` and `ether2` LAN on private vSwitch `10.151.10.0/24`):

1. **`NextHopType: Instance` defaults to Primary ENI:**
   Configuring custom routes in the VPC route table pointing to `NextHopType: Instance` (the ECS Instance ID `i-xxxx`) causes Alibaba Cloud's SDN fabric to inject traffic into the **Primary ENI (`ether1`)**, dropping packets from private LAN hosts.
   **Fix:** Point custom routes explicitly to `NextHopType: NetworkInterface` specifying the **Secondary ENI ID (`eni-xxxx`)** bound to the LAN subnet.

2. **Route Table Isolation for Peering / WAN Subnet:**
   Associating the peering vSwitch to the same route table as workload subnets creates an egress routing loop if `0.0.0.0/0 -> CHR` exists.
   **Fix:** Create a dedicated Custom Route Table (`nextops-peering-rt`) associated strictly to the peering vSwitch containing only intra-VPC local routes.

## 13. MikroTik RouterOS Point-to-Point Tunnel Sourcing for Ping/Fetch Tests

Running `/ping <remote-ip>` or `/tool/fetch` from RouterOS without specifying `src-address` causes RouterOS to source packets from the point-to-point `/30` link-local interface IP (`169.254.x.x`). Remote cloud VMs have UDRs only for the advertised VPC supernets (`10.151.0.0/18`) and drop replies to unroutable `169.254.x.x` addresses.
**Fix:** Always test with `src-address=<LAN_IP>` or `src-address=<WAN_IP>`, or verify directly from workload VMs.

