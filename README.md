# Alibaba Cloud (CHR) <---> Google Cloud Platform (CHR) Multi-Cloud Interconnect

This repository contains the Terraform infrastructure code and MikroTik RouterOS v7 configurations to build a high-performance, fault-tolerant **Multi-Cloud Hybrid Network** connecting **Alibaba Cloud (Jakarta)** and **Google Cloud Platform (Jakarta)** using dual **MikroTik Cloud Hosted Routers (CHR)** with **IPsec IKEv2, IPIP/GRE Tunnel, and Dynamic BGP Routing**.

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
|                          |       [MikroTik CHR: chr-peering (ASN 65534)]      |        |
+--------------------------+-----------------------------------------------------+--------+
                                                     |
                                   Route-based IPsec (IKEv2)
                                   + IPIP Tunnel: 10.254.254.0/30
                                   + eBGP Dynamic Routing
                                                     |
+----------------------------------------------------+------------------------------------+
|                                    GCP (asia-southeast2)                                |
|                                                                                         |
|                          +-----------------------------------------------------+        |
|                          |      [MikroTik CHR: gcp-chr-peering (ASN 65535)]    |        |
|                          |           /                         \              |        |
|                          |  Primary NIC (nic0)         Secondary NIC (nic1)   |        |
|                          |  10.160.0.10                10.160.10.100          |        |
|                          |  (Static External IP)       (Workload Subnet)      |        |
|                          +--------------------------+--------------------------+        |
|                                                     |                                   |
|                                         [GCP VPC: 10.160.0.0/16]                        |
+-----------------------------------------------------------------------------------------+
```

---

## 📋 Addressing & Subnet Plan

| Component | Cloud Provider | Subnet CIDR | IP Address | Description |
|---|---|---|---|---|
| **Alibaba CHR Primary** | Alibaba Cloud | `10.151.127.240/28` | `10.151.127.250` | Primary interface attached to Static EIP (`8.215.24.90`) |
| **Alibaba CHR Private** | Alibaba Cloud | `10.151.74.0/24` | `10.151.74.100` | Secondary ENI attached to private subnet |
| **Alibaba Workload VPC** | Alibaba Cloud | `10.151.64.0/18` | — | Internal VPC CIDR |
| **GCP CHR Primary** | Google Cloud | `10.160.0.0/28` | `10.160.0.10` | Primary NIC attached to Static Public IP |
| **GCP CHR Private** | Google Cloud | `10.160.10.0/24` | `10.160.10.100` | Secondary NIC attached to private workload subnet |
| **GCP Workload VPC** | Google Cloud | `10.160.0.0/16` | — | Internal GCP VPC CIDR |
| **Tunnel PTP Subnet** | Virtual (IPIP) | `10.254.254.0/30` | `.1` (Ali) / `.2` (GCP) | Point-to-point transit subnet for BGP peering |

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

### Step 3: Configure RouterOS v7
1. Apply the configuration script from `routeros/alibaba-chr-config.rsc.tmpl` onto Alibaba CHR.
2. Apply the configuration script from `routeros/gcp-chr-config.rsc.tmpl` onto GCP CHR.
3. Verify BGP session status:
   ```routeros
   /routing/bgp/session/print
   /ip/route/print where bgp
   ```

---

## 🔒 Security Best Practices
- Management access (SSH port `22` and Winbox port `8291`) is restricted strictly to the administrator IP.
- Pre-shared keys (PSK) and credentials are saved in environment variables (`vars.env`) and excluded from Git commits.
