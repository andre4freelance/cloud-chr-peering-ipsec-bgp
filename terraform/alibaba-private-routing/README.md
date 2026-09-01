# Aliyun Multi-Cloud VPC Routing Module

Custom Route Tables for Alibaba Cloud VPC (`managedservice-vpc`) to route multi-cloud interconnect traffic (Google Cloud Platform & Microsoft Azure) through MikroTik CHR Secondary Private ENI (`10.151.74.100`).

## Architecture & Subnet Scope

1. **Private Subnets (`managedservice-private-rt`):**
   * Attached to `vsw-k1as2atxwl1v5ls0bsgs3` (Zone A) and `vsw-k1au00ub252b1sbej2twq` (Zone B).
   * `0.0.0.0/0` -> Next-hop CHR Private ENI (`eni-k1ahx623o3hwm5j97ubx`).
   * `10.101.0.0/18` (GCP VPC) -> Next-hop CHR Private ENI.
   * `10.126.0.0/18` (Azure VNet) -> Next-hop CHR Private ENI.

2. **Public Subnets (`managedservice-public-rt`):**
   * Attached to `vsw-k1a75msk15j30llpntp11` (Zone A) and `vsw-k1a8d88b3c5ailyrafrht` (Zone B).
   * Direct internet routing (no default route override).
   * `10.101.0.0/18` (GCP VPC) -> Next-hop CHR Private ENI.
   * `10.126.0.0/18` (Azure VNet) -> Next-hop CHR Private ENI.

3. **Peering Subnet (`managedservice-peering-ap-southeast-5a`):**
   * Excluded from custom route tables (remains on default System Route Table) to avoid routing loops.
