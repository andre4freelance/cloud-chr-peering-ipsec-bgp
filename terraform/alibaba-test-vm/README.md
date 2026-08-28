# Aliyun Private Test VM Module

Deploys a small Ubuntu 24.04 LTS ECS instance into the private vSwitch (`10.151.74.0/24`) without any public IP / EIP.

## Specifications:
- **Resource Group:** `rg-aek3jxlnulgvj3i` (`ics-managed-service`)
- **VPC:** `vpc-k1ap3ij7ik4wgypdc1s5g`
- **vSwitch:** `vsw-k1as2atxwl1v5ls0bsgs3` (`managedservice-private-ap-southeast-5a`, `10.151.74.0/24`)
- **Security Group:** `sg-k1a4f91v9g26jt4rzn00` (`managedservice-private-sg`)
- **Instance Type:** `ecs.t6-c1m1.large` (2 vCPU, 1 GB RAM)
- **OS:** Ubuntu 24.04 LTS 64-bit (`ubuntu_24_04_x64_20G_alibase_20260810.vhd`)
- **SSH Key Pair:** `managedservice-test-key`
- **Internet / Egress:** Routed through MikroTik CHR NVA (`10.151.74.100` / `10.151.127.250`)
