# Multi-Cloud Hybrid Network Mesh (AWS, Alibaba Cloud, GCP, Azure)
### Dual-NIC MikroTik CHR NVA • Route-Based IPsec (IKEv2) • GRE Tunnels • Dynamic eBGP with Automated Transit Failover

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io)
[![MikroTik RouterOS](https://img.shields.io/badge/RouterOS-v7.x-2C5E8A?logo=mikrotik&logoColor=white)](https://mikrotik.com)
[![Multi-Cloud](https://img.shields.io/badge/Clouds-AWS%20|%20Alibaba%20|%20GCP%20|%20Azure-orange)](https://github.com/andre4freelance/cloud-chr-peering-ipsec-bgp)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Production-grade Infrastructure as Code (Terraform) and MikroTik RouterOS v7 templates to establish a high-performance, fault-tolerant, 4-node multi-cloud network mesh across **Amazon Web Services (AWS)**, **Alibaba Cloud (Aliyun)**, **Google Cloud Platform (GCP)**, and **Microsoft Azure**.

---

## 1. Architecture Overview

Each cloud environment deploys a **Dual-NIC Cloud-Native Network Virtual Appliance (NVA)** using MikroTik Cloud Hosted Router (CHR):

- **WAN / Peering Interface (`ether1`):** Placed behind 1:1 Cloud NAT in an isolated `/28` peering subnet with a dedicated Static Public IP / Elastic IP. Terminates IPsec IKEv2 SAs and GRE encapsulation.
- **LAN / Private Interface (`ether2`):** Placed directly in the VPC/VNet private workload subnet with IP Forwarding enabled. Acts as the internal default gateway / next-hop for cloud workloads.
- **Underlay Tunnel Layer:** Hardware-assisted AEAD AES-256-GCM encrypted IPsec IKEv2 point-to-point tunnels with link-local `/30` point-to-point addressing (`169.254.x.x/30`).
- **Overlay Routing Layer:** Dynamic eBGP full mesh with bidirectional route re-advertisement (`output.redistribute=bgp`) and deterministic distance-based path preference for automated transit failover.

```
                       +----------------------------------+
                       |      AWS Singapore (ap-se-1)     |
                       |      ASN: 65530                  |
                       |      VPC: 10.29.0.0/18           |
                       |      EIP: 52.76.246.237          |
                       +----------------------------------+
                        //              ||              \\
       169.254.103.0/30//               ||169.254.104.0/30\\169.254.105.0/30
                      //                ||                \\
                     //                 ||                 \\
+---------------------------+   169.254.100.0/30   +---------------------------+
| Alibaba Jakarta (ap-se-5) |<====================>|  GCP Jakarta (asia-se2)   |
| ASN: 65531                |                      |  ASN: 65532               |
| VPC: 10.151.0.0/18        |                      |  VPC: 10.101.0.0/16       |
| EIP: 8.215.24.90          |<===================\ |  Static IP: 34.101.118.166|
+---------------------------+  169.254.102.0/30  \\+---------------------------+
               \\                                 //
                \\                               // 169.254.101.0/30
                 \\                             //
                  +----------------------------+
                  |  Azure Jakarta (id-central)|
                  |  ASN: 65533                |
                  |  VNet: 10.126.0.0/18       |
                  |  Public IP: 70.153.184.179 |
                  +----------------------------+
```

---

## 2. Multi-Cloud Addressing & Interconnect Matrix

| Cloud Provider | Region | ASN | Peering WAN (ether1) | Private LAN (ether2) | Supernet CIDR | Instance Type |
|---|---|---|---|---|---|---|
| **AWS** | `ap-southeast-1` (Singapore) | `65530` | `10.29.63.250/28` | `10.29.16.100/20` | `10.29.0.0/18` | `t3.medium` (2 vCPU, 4 GB) |
| **Alibaba Cloud** | `ap-southeast-5` (Jakarta) | `65531` | `10.151.63.250/28` | `10.151.10.100/24` | `10.151.0.0/18` | `ecs.t6-c1m1.large` (2 vCPU, 2 GB) |
| **Google Cloud (GCP)** | `asia-southeast2` (Jakarta) | `65532` | `10.101.16.10/28` | `10.101.0.10/22` | `10.101.0.0/16` | `e2-standard-2` (2 vCPU, 8 GB) |
| **Microsoft Azure** | `indonesiacentral` (Jakarta) | `65533` | `10.126.63.250/28` | `10.126.1.100/24` | `10.126.0.0/18` | `Standard_D2as_v4` (2 vCPU, 8 GB) |

### Point-to-Point Tunnel Interconnects (/30 Subnets)
* **Alibaba <---> GCP:** `169.254.100.0/30` (`.1` Alibaba, `.2` GCP)
* **Azure <---> GCP:** `169.254.101.0/30` (`.1` Azure, `.2` GCP)
* **Azure <---> Alibaba:** `169.254.102.0/30` (`.1` Azure, `.2` Alibaba)
* **AWS <---> Alibaba:** `169.254.103.0/30` (`.1` AWS, `.2` Alibaba)
* **AWS <---> GCP:** `169.254.104.0/30` (`.1` AWS, `.2` GCP)
* **AWS <---> Azure:** `169.254.105.0/30` (`.1` AWS, `.2` Azure)

---

## 3. Dynamic BGP Routing & Automated Transit Failover

To prevent routing loops while enabling high-availability transit routing:
1. **Direct Path Preference:** Direct peer prefixes are assigned `distance 20` (Active Primary Route in RIB).
2. **Transit Path Backup:** Re-advertised prefixes received via third-party nodes are assigned `distance 30` (Backup Candidate Route in RIB).
3. **Automated Convergence:** If a direct IPsec tunnel or underlay ISP path fails, traffic dynamically fails over to alternate transit nodes within < 2 seconds with zero packet drop.

```
Route Table State (Example: AWS -> Azure 10.126.0.0/18):
Normal:
  [DAb] 10.126.0.0/18 via 169.254.105.2 (Direct Azure)   distance=20  (ACTIVE)
  [D b] 10.126.0.0/18 via 169.254.103.2 (Transit Ali)    distance=30  (BACKUP)
  [D b] 10.126.0.0/18 via 169.254.104.2 (Transit GCP)    distance=30  (BACKUP)

Direct Link Failure:
  [DAb+] 10.126.0.0/18 via 169.254.103.2 (Transit Ali)   distance=30  (ACTIVE ECMP)
  [DAb+] 10.126.0.0/18 via 169.254.104.2 (Transit GCP)   distance=30  (ACTIVE ECMP)
```

---

## 4. Performance & Bandwidth Benchmark

Measured using hardware-assisted AEAD `aes-256-gcm` IPsec encryption across live cloud production backbones:

| Segment | Path Type | Round-Trip Latency | TCP Throughput (TX / RX) | Aggregate Bandwidth |
|---|---|---|---|---|
| **AWS <---> Azure** | Direct Cross-Region | **~19.6 ms** | **1.12 Gbps** / **434 Mbps** | **~1.55 Gbps** |
| **AWS <---> GCP** | Direct Cross-Region | **~15.9 ms** | **566 Mbps** / **631 Mbps** | **~1.20 Gbps** |
| **AWS <---> Alibaba** | Direct Cross-Region | **~13.8 ms** | **91 Mbps** / **96 Mbps** | **~187 Mbps** *(EIP Capped)* |
| **Alibaba <---> GCP** | Local Jakarta IXP | **~2.1 ms** | **94 Mbps** / **91 Mbps** | **~185 Mbps** *(EIP Capped)* |
| **Azure <---> GCP** | Direct Cloud Peering | **~30.6 ms** | **407 Mbps** / **878 Mbps** | **~1.28 Gbps** |
| **Azure <---> Alibaba**| Direct Cloud Peering | **~15.1 ms** | **95 Mbps** / **91 Mbps** | **~186 Mbps** *(EIP Capped)* |

---

## 5. Repository Structure

```
├── README.md                          # Architecture documentation and multi-cloud matrix
├── vars.env.example                   # Environment variable template (Zero hardcoded secrets)
├── docs/                              # Engineering deep-dives and operational lessons
│   └── lessons.md
├── routeros/                          # RouterOS v7 templates per provider
│   ├── alibaba-chr-config.rsc.tmpl
│   ├── azure-chr-config.rsc.tmpl
│   └── gcp-chr-config.rsc.tmpl
└── terraform/                         # Terraform modular infrastructure
    ├── aws-chr/                       # AWS EC2 Dual-NIC, EIP, and Security Groups
    ├── aws-peering-subnet/            # AWS dedicated peering /28 subnet and isolated RTB
    ├── alibaba-chr/                   # Alibaba Cloud ECS Dual-NIC & EIP
    ├── alibaba-peering-subnet/        # Alibaba Cloud dedicated peering vSwitch
    ├── alibaba-private-routing/       # Alibaba Cloud VPC Route Table custom next-hop rules
    ├── azure-chr/                     # Azure VM Dual-NIC, Public IP, CMK & NSG
    ├── azure-peering-subnet/          # Azure dedicated peering subnet
    ├── azure-private-routing/         # Azure Route Table UDR rules
    ├── gcp-chr/                       # GCP Compute Engine Dual-NIC & Static IP
    └── gcp-private-routing/           # GCP Shared VPC custom routes
```

---

## 6. Security & Best Practices

- **Zero Hardcoded Secrets:** Pre-shared keys (PSK), SSH keys, and credentials are parameterized strictly via environment variables (`vars.env` is gitignored).
- **1:1 NAT Routing Isolation:** Separate routing tables ensure NVA WAN interfaces only route locally to the Internet Gateway, eliminating routing loops.
- **MSS Clamping:** TCP SYN MSS clamping (`new-mss=1360`) is enforced on all tunnel interfaces to eliminate packet fragmentation over MTU-constrained encapsulation tunnels.
- **Source/Dest Checking:** Disabled explicitly on all Cloud NVAs (`source_dest_check = false` / IP Forwarding enabled).

---

## 7. License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
