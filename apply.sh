#!/usr/bin/env bash
# Render and apply the tunnel configuration to both MikroTik CHRs.
#
#   ./apply.sh render          # render both templates, print with the PSK redacted
#   ./apply.sh ali             # apply the Alibaba side
#   ./apply.sh gcp             # apply the GCP side
#   ./apply.sh both            # apply Alibaba then GCP
#   ./apply.sh status          # IPsec / GRE / BGP / route state on both ends
#
# Reads vars.env. Never prints the PSK.
#
# SSH targets default to the `chr-ali` / `chr-gcp` aliases in ~/.ssh/config;
# override with ALI_SSH / GCP_SSH.
set -euo pipefail
cd "$(dirname "$0")"
[ -f vars.env ] || { echo "vars.env missing - copy vars.env.example"; exit 1; }
set -a; . ./vars.env; set +a
: "${IPSEC_PSK:?}"; [ "$IPSEC_PSK" = "CHANGE_ME" ] && { echo "set a real IPSEC_PSK"; exit 1; }

ALI_SSH="${ALI_SSH:-chr-ali}"
GCP_SSH="${GCP_SSH:-chr-gcp}"

OUT=$(mktemp -d); trap 'rm -rf "$OUT"' EXIT

# Shared substitutions. Both templates draw from the same variable set, so the
# two sides can never drift into non-mirrored selectors.
render() {
  sed -e "s|@@ALI_PUBLIC_IP@@|$ALI_PUBLIC_IP|g" \
      -e "s|@@ALI_PEERING_IP@@|$ALI_PEERING_IP|g" \
      -e "s|@@ALI_PRIVATE_IP@@|$ALI_PRIVATE_IP|g" \
      -e "s|@@ALI_PRIVATE_SUBNET@@|$ALI_PRIVATE_SUBNET|g" \
      -e "s|@@ALI_ASN@@|$ALI_ASN|g" \
      -e "s|@@ALI_SUPERNET@@|$ALI_SUPERNET|g" \
      -e "s|@@ALI_TUNNEL_IP@@|$ALI_TUNNEL_IP|g" \
      -e "s|@@GCP_PUBLIC_IP@@|$GCP_PUBLIC_IP|g" \
      -e "s|@@GCP_PEERING_IP@@|$GCP_PEERING_IP|g" \
      -e "s|@@GCP_PRIVATE_IP@@|$GCP_PRIVATE_IP|g" \
      -e "s|@@GCP_ASN@@|$GCP_ASN|g" \
      -e "s|@@GCP_SUPERNET@@|$GCP_SUPERNET|g" \
      -e "s|@@GCP_TUNNEL_IP@@|$GCP_TUNNEL_IP|g" \
      -e "s|@@TUNNEL_NETWORK@@|$TUNNEL_NETWORK|g" \
      -e "s|@@TUNNEL_MTU@@|$TUNNEL_MTU|g" \
      -e "s|@@TUNNEL_MSS@@|$TUNNEL_MSS|g" \
      -e "s|@@TIMEZONE@@|$TIMEZONE|g" \
      -e "s|@@IPSEC_PSK@@|$IPSEC_PSK|g" \
      "$1"
}

# Objects each template re-adds. Removed first so re-running is idempotent —
# RouterOS `add` duplicates rather than replaces.
#
# NOTE: unlike the CHR<->pfSense version of this script, /ip/dhcp-client is
# deliberately NOT removed. Both CHRs get every interface address from DHCP and
# the templates do not re-add the clients, so wiping them drops the addresses,
# the default route, and the SSH session applying the config.
cleanup_cmds() {
  local peer="$1" chain="$2" gre="$3" conn="$4" al="$5"
  cat <<EOF
/routing/bgp/connection remove [find name="$conn"];
/routing/bgp/instance remove [find name="$peer"];
/routing/bgp/template remove [find name="$peer"];
/routing/filter/rule remove [find chain~"$chain"];
/ip/firewall/address-list remove [find list="$al"];
/ip/ipsec/policy remove [find peer="$peer"];
/ip/ipsec/identity remove [find peer="$peer"];
/ip/ipsec/peer remove [find name="$peer"];
/ip/ipsec/proposal remove [find name="$peer"];
/ip/ipsec/profile remove [find name="$peer"];
/ip/address remove [find interface="$gre"];
/interface/gre remove [find name="$gre"];
/ip/route remove [find comment="vpc network"];
/ip/route remove [find comment="peer gre endpoint, encrypted by the ipsec policy"];
/ip/firewall/mangle remove [find comment="clamp tcp mss to the measured path mtu"];
/ip/firewall/nat remove [find comment="NAT private subnet to the internet, never to the peer"];
EOF
}

apply_side() {
  local host="$1" tmpl="$2" peer="$3" chain="$4" gre="$5" conn="$6" al="$7"
  render "$tmpl" > "$OUT/t.rsc"
  echo "[$host] removing objects this template re-adds..."
  cleanup_cmds "$peer" "$chain" "$gre" "$conn" "$al" | ssh "$host" >/dev/null 2>&1 || true
  scp -q "$OUT/t.rsc" "$host:/tunnel.rsc"
  echo "[$host] importing..."
  # RouterOS /import reports failures on stdout and still exits 0, so a plain
  # `ssh ... || echo failed` claims success on a broken config. Grep the output.
  local log="$OUT/import.log"
  ssh "$host" '/import file-name=tunnel.rsc; /file remove [find name=tunnel.rsc]' 2>&1 | tee "$log"
  if grep -qiE "script error|syntax error|bad parameter|failure|expected end of command" "$log"; then
    echo "[$host] IMPORT FAILED — the config is PARTIALLY applied. Fix the template and re-run." >&2
    return 1
  fi
  echo "[$host] applied."
}

case "${1:-}" in
  render)
    for t in routeros/chr-ali-tunnel.rsc.tmpl routeros/chr-gcp-tunnel.rsc.tmpl; do
      echo "########## $t ##########"
      render "$t" | sed "s|$IPSEC_PSK|<PSK-REDACTED>|g"
    done
    ;;
  ali)
    apply_side "$ALI_SSH" routeros/chr-ali-tunnel.rsc.tmpl gcp gcp gre-gcp chr-gcp ali-advertise
    # The stock Alibaba CHR image ships a bare `chain=srcnat action=masquerade`
    # rule that matches everything, tunnel traffic included. The template adds a
    # scoped replacement; drop the unscoped original.
    ssh "$ALI_SSH" '/ip/firewall/nat remove [find where chain=srcnat action=masquerade !out-interface]' || true
    ;;
  gcp)
    apply_side "$GCP_SSH" routeros/chr-gcp-tunnel.rsc.tmpl ali ali gre-ali chr-ali gcp-advertise
    ;;
  both)
    "$0" ali
    "$0" gcp
    ;;
  status)
    for h in "$ALI_SSH" "$GCP_SSH"; do
      echo "########## $h ##########"
      ssh "$h" '
        :put "--- ipsec active peers ---";
        /ip/ipsec/active-peers/print without-paging;
        :put "--- ipsec sa (direction counters) ---";
        /ip/ipsec/installed-sa/print without-paging;
        :put "--- ipsec policy ---";
        /ip/ipsec/policy/print without-paging;
        :put "--- gre ---";
        /interface/gre/print without-paging;
        :put "--- bgp session ---";
        /routing/bgp/session/print without-paging;
        :put "--- bgp advertisements ---";
        /routing/bgp/advertisements/print without-paging;
        :put "--- routes learned via bgp ---";
        /ip/route/print without-paging where bgp;
      ' || true
    done
    ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
