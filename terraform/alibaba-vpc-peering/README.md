# Alibaba Cloud VPC Peering Module

VPC Peering connection between `managedservice-vpc` (`10.151.64.0/18` - Hub) and `nextops-vpc` (`10.151.0.0/18` - Production Spoke) in Alibaba Cloud (`ap-southeast-5`).

## Features
- Provisions intra-region `alicloud_vpc_peer_connection` across resource groups (`rg-aek3jxlnulgvj3i` <-> `rg-aek46fmc2ohclmi`).
- Configures bidirectional static routing across:
  - `managedservice-private-rt` (Hub Private subnets) -> `10.151.0.0/18`
  - `managedservice-public-rt` (Hub Public subnets) -> `10.151.0.0/18`
  - `managedservice-vpc System Route Table` (Hub Peering subnet) -> `10.151.0.0/18`
  - `nextops-vpc System Route Table` (Spoke Public & Private subnets) -> `10.151.64.0/18` (Hub), `10.101.0.0/18` (GCP), `10.126.0.0/18` (Azure).
