#!/usr/bin/env bash
# =============================================================================
# Multi-Cloud MikroTik CHR Configuration Generator & Deployment Script
# 4-Node Full Mesh (AWS, Alibaba Cloud, Google Cloud, Microsoft Azure)
#
# Usage:
#   ./apply.sh render [node]   # render templates with secrets redacted (aws|ali|gcp|azure|all)
#   ./apply.sh status [node]   # check IPsec, BGP, GRE, and Route health on live CHRs
#   ./apply.sh apply <node>    # apply configuration to target router (aws|ali|gcp|azure|all)
# =============================================================================

set -euo pipefail
cd "$(dirname "$0")"

CONFIG_FILE="vars.env"
if [ ! -f "$CONFIG_FILE" ]; then
  if [ -f "vars.env.example" ]; then
    CONFIG_FILE="vars.env.example"
  else
    echo "Error: vars.env or vars.env.example missing." >&2
    exit 1
  fi
fi

# Load variables safely
eval "$(python3 -c "
with open('$CONFIG_FILE') as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'): continue
        if '#' in line: line = line.split('#')[0].strip()
        if '=' in line:
            k, v = line.split('=', 1)
            print(f'{k.strip()}={v.strip()}')
")"

AWS_SSH="${AWS_SSH:-chr-aws}"
ALI_SSH="${ALI_SSH:-chr-ali}"
GCP_SSH="${GCP_SSH:-chr-gcp}"
AZURE_SSH="${AZURE_SSH:-chr-azure}"

OUT=$(mktemp -d); trap 'rm -rf "$OUT"' EXIT

render_file() {
  local src="$1"
  sed \
    -e "s|__AWS_PUBLIC_IP__|$AWS_PUBLIC_IP|g" \
    -e "s|__AWS_PEERING_IP__|$AWS_PEERING_IP|g" \
    -e "s|__AWS_PRIVATE_IP__|$AWS_PRIVATE_IP|g" \
    -e "s|__AWS_ASN__|$AWS_ASN|g" \
    -e "s|__AWS_SUPERNET__|$AWS_SUPERNET|g" \
    -e "s|__ALI_PUBLIC_IP__|$ALI_PUBLIC_IP|g" \
    -e "s|__ALI_PEERING_IP__|$ALI_PEERING_IP|g" \
    -e "s|__ALI_PRIVATE_IP__|$ALI_PRIVATE_IP|g" \
    -e "s|__ALI_ASN__|$ALI_ASN|g" \
    -e "s|__ALI_SUPERNET__|$ALI_SUPERNET|g" \
    -e "s|__GCP_PUBLIC_IP__|$GCP_PUBLIC_IP|g" \
    -e "s|__GCP_PEERING_IP__|$GCP_PEERING_IP|g" \
    -e "s|__GCP_PRIVATE_IP__|$GCP_PRIVATE_IP|g" \
    -e "s|__GCP_ASN__|$GCP_ASN|g" \
    -e "s|__GCP_SUPERNET__|$GCP_SUPERNET|g" \
    -e "s|__AZURE_PUBLIC_IP__|$AZURE_PUBLIC_IP|g" \
    -e "s|__AZURE_PEERING_IP__|$AZURE_PEERING_IP|g" \
    -e "s|__AZURE_PRIVATE_IP__|$AZURE_PRIVATE_IP|g" \
    -e "s|__AZURE_ASN__|$AZURE_ASN|g" \
    -e "s|__AZURE_SUPERNET__|$AZURE_SUPERNET|g" \
    -e "s|__ALI_GCP_TUNNEL_ALI_IP__|$ALI_GCP_TUNNEL_ALI_IP|g" \
    -e "s|__ALI_GCP_TUNNEL_GCP_IP__|$ALI_GCP_TUNNEL_GCP_IP|g" \
    -e "s|__ALI_GCP_TUNNEL_NETWORK__|$ALI_GCP_TUNNEL_NETWORK|g" \
    -e "s|__AZURE_GCP_TUNNEL_AZURE_IP__|$AZURE_GCP_TUNNEL_AZURE_IP|g" \
    -e "s|__AZURE_GCP_TUNNEL_GCP_IP__|$AZURE_GCP_TUNNEL_GCP_IP|g" \
    -e "s|__AZURE_GCP_TUNNEL_NETWORK__|$AZURE_GCP_TUNNEL_NETWORK|g" \
    -e "s|__AZURE_ALI_TUNNEL_AZURE_IP__|$AZURE_ALI_TUNNEL_AZURE_IP|g" \
    -e "s|__AZURE_ALI_TUNNEL_ALI_IP__|$AZURE_ALI_TUNNEL_ALI_IP|g" \
    -e "s|__AZURE_ALI_TUNNEL_NETWORK__|$AZURE_ALI_TUNNEL_NETWORK|g" \
    -e "s|__AWS_ALI_TUNNEL_AWS_IP__|$AWS_ALI_TUNNEL_AWS_IP|g" \
    -e "s|__AWS_ALI_TUNNEL_ALI_IP__|$AWS_ALI_TUNNEL_ALI_IP|g" \
    -e "s|__AWS_ALI_TUNNEL_NETWORK__|$AWS_ALI_TUNNEL_NETWORK|g" \
    -e "s|__AWS_GCP_TUNNEL_AWS_IP__|$AWS_GCP_TUNNEL_AWS_IP|g" \
    -e "s|__AWS_GCP_TUNNEL_GCP_IP__|$AWS_GCP_TUNNEL_GCP_IP|g" \
    -e "s|__AWS_GCP_TUNNEL_NETWORK__|$AWS_GCP_TUNNEL_NETWORK|g" \
    -e "s|__AWS_AZURE_TUNNEL_AWS_IP__|$AWS_AZURE_TUNNEL_AWS_IP|g" \
    -e "s|__AWS_AZURE_TUNNEL_AZURE_IP__|$AWS_AZURE_TUNNEL_AZURE_IP|g" \
    -e "s|__AWS_AZURE_TUNNEL_NETWORK__|$AWS_AZURE_TUNNEL_NETWORK|g" \
    -e "s|__TUNNEL_MTU__|$TUNNEL_MTU|g" \
    -e "s|__TUNNEL_MSS__|$TUNNEL_MSS|g" \
    -e "s|__IPSEC_PSK_ALI_GCP__|${IPSEC_PSK_ALI_GCP:-CHANGE_ME}|g" \
    -e "s|__IPSEC_PSK_AZURE_GCP__|${IPSEC_PSK_AZURE_GCP:-CHANGE_ME}|g" \
    -e "s|__IPSEC_PSK_AZURE_ALI__|${IPSEC_PSK_AZURE_ALI:-CHANGE_ME}|g" \
    -e "s|__IPSEC_PSK_AWS_ALI__|${IPSEC_PSK_AWS_ALI:-CHANGE_ME}|g" \
    -e "s|__IPSEC_PSK_AWS_GCP__|${IPSEC_PSK_AWS_GCP:-CHANGE_ME}|g" \
    -e "s|__IPSEC_PSK_AWS_AZURE__|${IPSEC_PSK_AWS_AZURE:-CHANGE_ME}|g" \
    "$src"
}

check_status() {
  local host="$1"
  local name="$2"
  echo "================================================================="
  echo " NODE: $name ($host)"
  echo "================================================================="
  ssh -o ConnectTimeout=5 "$host" '
    :put "--- [1] System Identity & Resources ---";
    /system/identity/print;
    :put "--- [2] IP Addresses & Interfaces ---";
    /ip/address/print without-paging;
    :put "--- [3] IPsec Active Peers & SAs ---";
    /ip/ipsec/active-peers/print without-paging;
    /ip/ipsec/installed-sa/print without-paging;
    :put "--- [4] GRE Tunnels ---";
    /interface/gre/print without-paging;
    :put "--- [5] BGP Sessions & Prefixes ---";
    /routing/bgp/session/print without-paging;
    :put "--- [6] Active Learned BGP Routes ---";
    /ip/route/print without-paging where bgp;
  ' || echo "Error: Failed to reach $host"
  echo ""
}

apply_node() {
  local host="$1"
  local tmpl="$2"
  local name="$3"
  echo "[$name] Rendering $tmpl..."
  render_file "$tmpl" > "$OUT/deploy.rsc"
  echo "[$name] Uploading configuration to $host..."
  scp -q "$OUT/deploy.rsc" "$host:/deploy.rsc"
  echo "[$name] Executing RouterOS import..."
  ssh "$host" '/import file-name=deploy.rsc; /file remove [find name=deploy.rsc]'
  echo "[$name] Deployment finished successfully."
}

ACTION="${1:-help}"
TARGET="${2:-all}"

case "$ACTION" in
  render)
    for node in aws alibaba gcp azure; do
      if [ "$TARGET" = "all" ] || [ "$TARGET" = "$node" ]; then
        tmpl="routeros/${node}-chr-config.rsc.tmpl"
        echo "#################################################################"
        echo "# TEMPLATE: $tmpl"
        echo "#################################################################"
        render_file "$tmpl" | sed -E 's/(secret=)"[^"]+"/\1"<PSK-REDACTED>"/g'
        echo ""
      fi
    done
    ;;
  status)
    case "$TARGET" in
      aws) check_status "$AWS_SSH" "AWS CHR" ;;
      ali|alibaba) check_status "$ALI_SSH" "Alibaba CHR" ;;
      gcp) check_status "$GCP_SSH" "GCP CHR" ;;
      azure) check_status "$AZURE_SSH" "Azure CHR" ;;
      all)
        check_status "$AWS_SSH" "AWS CHR"
        check_status "$ALI_SSH" "Alibaba CHR"
        check_status "$GCP_SSH" "GCP CHR"
        check_status "$AZURE_SSH" "Azure CHR"
        ;;
      *) echo "Unknown target: $TARGET (use aws|ali|gcp|azure|all)"; exit 1 ;;
    esac
    ;;
  apply)
    case "$TARGET" in
      aws) apply_node "$AWS_SSH" "routeros/aws-chr-config.rsc.tmpl" "AWS CHR" ;;
      ali|alibaba) apply_node "$ALI_SSH" "routeros/alibaba-chr-config.rsc.tmpl" "Alibaba CHR" ;;
      gcp) apply_node "$GCP_SSH" "routeros/gcp-chr-config.rsc.tmpl" "GCP CHR" ;;
      azure) apply_node "$AZURE_SSH" "routeros/azure-chr-config.rsc.tmpl" "Azure CHR" ;;
      all)
        apply_node "$AWS_SSH" "routeros/aws-chr-config.rsc.tmpl" "AWS CHR"
        apply_node "$ALI_SSH" "routeros/alibaba-chr-config.rsc.tmpl" "Alibaba CHR"
        apply_node "$GCP_SSH" "routeros/gcp-chr-config.rsc.tmpl" "GCP CHR"
        apply_node "$AZURE_SSH" "routeros/azure-chr-config.rsc.tmpl" "Azure CHR"
        ;;
      *) echo "Unknown target: $TARGET (use aws|ali|gcp|azure|all)"; exit 1 ;;
    esac
    ;;
  *)
    echo "Usage: $0 {render|status|apply} [aws|ali|gcp|azure|all]"
    exit 1
    ;;
esac
