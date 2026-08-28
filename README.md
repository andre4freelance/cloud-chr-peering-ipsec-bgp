# Alibaba Cloud (CHR) <---> Google Cloud Platform (CHR) Multi-Cloud Interconnect

This repository contains the Terraform infrastructure code and MikroTik RouterOS v7 configurations to build a high-performance, fault-tolerant **Multi-Cloud Hybrid Network** connecting **Alibaba Cloud (Jakarta)** and **Google Cloud Platform (Jakarta)** using dual **MikroTik Cloud Hosted Routers (CHR)** with **IPsec IKEv2, GRE Tunnel, and Dynamic BGP Routing**.

---

## 🏗️ Network Architecture & Topology

```
+-----------------------------------------------------------------------------------------+
|                                ALIBABA CLOUD (ap-southeast-5)                           |
|                                                                                         |
|  [Spoke VPC / Workload] <--(VPC Peering)--> [Hub VPC: 10.151.64.0/18]                   |
|                                                     |                                   |
|                          +--------------------------+--------------------------+        |
|                          |  Primary NIC (eth0)         Secondary ENI (eth1)   |        |
|                          |  10.151.127.250             10.151.74.100          |        |
|                          |  (EIP: 8.215.24.90)         (Private Subnet 5a)    |        |
|                          |           \                         /              |        |
|                          |       [MikroTik CHR: chr-peering (ASN 65531)]      |        |
|                          +-----------------------------------------------------+        |
+--------------------------+-----------------------------------------------------+--------+
                                                     |
                                   Route-based IPsec (IKEv2)
                                   + GRE Tunnel: 169.254.100.0/30
                                   + eBGP Dynamic Routing
                                                     |
+----------------------------------------------------+------------------------------------+
|                                    GCP (asia-southeast2)                                |
|                                                                                         |
|                          +-----------------------------------------------------+        |
|                          |        [MikroTik CHR: chr-peering (ASN 65532)]      |        |
|                          |           /                         \              |        |
|                          |  Primary NIC (nic0)         Secondary NIC (nic1)   |        |
|                          |  10.101.16.10               10.101.0.10            |        |
|                          |  (Static IP: 34.101.118.166)(Production Subnet)    |        |
|                          +--------------------------+--------------------------+        |
|                                                     |                                   |
|                                [GCP Shared VPC: 10.101.0.0/16]                          |
+-----------------------------------------------------------------------------------------+
```

---

## 📋 Addressing & Subnet Plan

| Component | Cloud Provider | Subnet CIDR | IP Address | Description |
|---|---|---|---|---|
| **Alibaba CHR Primary** | Alibaba Cloud | `10.151.127.240/28` | `10.151.127.250` | Primary interface attached to Static EIP (`8.215.24.90`) |
| **Alibaba CHR Private** | Alibaba Cloud | `10.151.74.0/24` | `10.151.74.100` | Secondary ENI attached to private subnet |
| **Alibaba Workload VPC** | Alibaba Cloud | `10.151.64.0/18` | — | Internal VPC CIDR |
| **GCP CHR Primary** | Google Cloud | `10.101.16.0/28` | `10.101.16.10` | Primary NIC attached to Static Public IP (`34.101.118.166`) |
| **GCP CHR Private** | Google Cloud | `10.101.0.0/22` | `10.101.0.10` | Secondary NIC attached to production workload subnet |
| **GCP Shared VPC** | Google Cloud | `10.101.0.0/16` | — | Internal GCP Shared VPC Supernet |
| **Tunnel PTP Subnet** | Virtual (GRE) | `169.254.100.0/30` | `.1` (Ali) / `.2` (GCP) | Point-to-point transit subnet for BGP peering |

**Advertised prefixes:** Alibaba advertises `10.151.64.0/18` (its whole VPC); GCP
advertises `10.101.0.0/18`. Note the GCP Shared VPC is a `/16`, so the `/18`
covers `nextops-prod` (`10.101.0.0/22`) and the peering subnet only — the
`nextops-data` (`.64`), `ics-ms-sandbox` (`.128`) and `nextops-infra` (`.192`)
subnets are deliberately **not** advertised and stay unreachable from Alibaba.
Widen the prefix on both sides if that changes.

**Tunnel MTU 1400 / MSS 1360** — measured, not assumed. Across the live tunnel a
1410-byte `do-not-fragment` ping is lost and 1400 passes.

---

## 🚀 Deployment Guide

### Step 1: Deploy Alibaba Cloud CHR
```bash
cd terraform/alibaba-chr
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

### Step 2: Deploy GCP CHR
```bash
cd terraform/gcp-chr
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

### Step 3: Configure both CHRs

`apply.sh` renders `routeros/chr-ali-tunnel.rsc.tmpl` and
`routeros/chr-gcp-tunnel.rsc.tmpl` from a single `vars.env`, so the two ends
cannot drift into non-mirrored selectors. Both templates are idempotent: the
script removes the objects they re-add before importing.

```bash
cp vars.env.example vars.env      # then set IPSEC_PSK: openssl rand -base64 32
./apply.sh render                 # inspect the rendered config (PSK redacted)
./apply.sh both                   # apply Alibaba then GCP
./apply.sh status                 # IPsec / GRE / BGP / route state on both ends
```

SSH targets default to the `chr-ali` / `chr-gcp` aliases in `~/.ssh/config`;
override with `ALI_SSH` / `GCP_SSH`.

### Step 4: Verify

```routeros
/ip/ipsec/installed-sa/print       # two mature SAs with PAIRED SPIs, both ends
/routing/bgp/session/print         # E flag, prefix-count=1
/ip/route/print where bgp          # peer supernet via the tunnel address
```

End-to-end, private to private, no NAT:

```routeros
# on chr-ali
/ping 10.101.0.10 src-address=10.151.74.100
# on chr-gcp
/ping 10.151.74.100 src-address=10.101.0.10
```

**Read the direction counters early.** An SA that is `mature` while GRE shows
`RX=0` is a decrypt failure, not a routing problem — check
`/ip/ipsec/statistics` for `in-state-protocol-errors` climbing. See
[docs/lessons.md](docs/lessons.md).

---

## 🔒 Security Best Practices
- Management access (SSH port `22` and Winbox port `8291`) is restricted strictly to administrator IPs.
- IPsec (UDP 500, 4500) and GRE/Tunnel traffic is restricted strictly between the two public IPs (`8.215.24.90` and `34.101.118.166`).
- Pre-shared keys (PSK) and credentials are excluded from Git commits.
