# Multi-Cloud CHR Interconnect (IPsec IKEv2 + GRE / IPIP + eBGP)

This repository contains Terraform infrastructure modules and MikroTik RouterOS v7 templates to build a modular, high-performance, fault-tolerant Multi-Cloud Hybrid Network Mesh connecting cloud providers (Alibaba Cloud, Google Cloud Platform, Microsoft Azure, AWS) using MikroTik Cloud Hosted Routers (CHR) with Route-based IPsec (IKEv2), GRE/IPIP Tunnels, and Dynamic eBGP Routing.

---

## 1. Architecture and Multi-Cloud Mesh Model

The design employs a Dual-NIC Cloud-Native Network Virtual Appliance (NVA) pattern deployed across multiple cloud environments, where each router operates with:
- **WAN/Peering NIC (NIC 0 / ether1):** Sits behind 1:1 NAT with Static Public IP / EIP for IPsec SA termination and GRE/IPIP tunnel transport.
- **LAN/Private NIC (NIC 1 / ether2):** Connected to the local Cloud VPC/VNet with IP Forwarding enabled for internal routing and transit.
- **Underlay Tunnel:** Link-Local (/30) point-to-point interconnect (`169.254.x.x/30`) over IPsec.
- **Overlay Routing:** eBGP peering with bidirectional route advertisement and dynamic convergence.

```
+---------------------------+       IPsec + GRE / IPIP Tunnel       +---------------------------+
|    Alibaba Cloud (Jakarta)| <===================================> |       GCP (Jakarta)       |
|    CHR ASN 65531          |           (169.254.100.0/30)          |       CHR ASN 65532       |
|    VPC: 10.151.0.0/18     |                                       |       VPC: 10.101.0.0/16  |
+---------------------------+                                       +---------------------------+
              ^                                                                   ^
              |                      Route-Based IPsec & eBGP                     |
              +=============================+=====================================+
                                            |
                                            v
                            +-------------------------------+
                            |     Microsoft Azure (Jakarta) |
                            |     CHR ASN 65533             |
                            |     VNet: 10.126.0.0/18       |
                            +-------------------------------+
```

---

## 2. Multi-Cloud Addressing and ASN Allocation Plan

| Cloud Provider | Region | ASN | Peering / WAN Subnet | Private / Workload Subnet | VPC/VNet Supernet |
|---|---|---|---|---|---|
| **Alibaba Cloud** | `ap-southeast-5` (Jakarta) | `65531` | `10.151.63.240/28` | `10.151.10.0/24` | `10.151.0.0/18` |
| **Google Cloud (GCP)** | `asia-southeast2` (Jakarta) | `65532` | `10.101.16.0/28` | `10.101.0.0/22` | `10.101.0.0/18` |
| **Microsoft Azure** | `indonesiacentral` (Jakarta) | `65533` | `10.126.16.0/28` | `10.126.0.0/22` | `10.126.0.0/18` |

### Inter-Cloud Tunnel Matrix (/30 Link-Local Subnets)
- **Alibaba <---> GCP:** `169.254.100.0/30` (`.1` Alibaba, `.2` GCP)
- **Azure <---> GCP:** `169.254.101.0/30` (`.1` Azure, `.2` GCP)
- **Azure <---> Alibaba:** `169.254.102.0/30` (`.1` Azure, `.2` Alibaba)

---

## 3. Repository Structure

```
├── README.md               # Architecture documentation and multi-cloud matrix
├── vars.env.example        # Environment variable template for RouterOS script generation
├── apply.sh                # Automation script to render and push configurations to CHR routers
├── docs/                   # Engineering lessons, MTU/MSS deep-dives, and routing caveats
├── routeros/               # RouterOS v7 templates per provider
│   ├── alibaba-chr-config.rsc.tmpl
│   ├── gcp-chr-config.rsc.tmpl
│   ├── azure-chr-config.rsc.tmpl
│   └── chr-*-tunnel.rsc.tmpl
└── terraform/              # Terraform modules per cloud
    ├── alibaba-chr/        # Alibaba Cloud ECS Dual-NIC & EIP
    ├── gcp-chr/            # GCP Compute Engine Dual-NIC & Static IP
    ├── azure-chr/          # Azure VM Dual-NIC, Public IP, CMK & NSG
    └── alibaba-test-vm/    # Test workloads
```

---

## 4. Security and Operational Standards

- **Zero Hardcoded Secrets:** Pre-shared keys (PSK) and credentials are parameterized strictly via `vars.env` (gitignored).
- **1:1 NAT Aware Routing:** Dual-NIC configuration cleanly isolates public peering transport from internal workload VPC routing.
- **MSS Clamping:** TCP SYN MSS clamping is automatically enforced on all tunnel interfaces to prevent packet fragmentation over MTU-constrained encapsulation tunnels.
