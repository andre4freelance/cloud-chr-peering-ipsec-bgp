# Aliyun Private vSwitch Custom Routing Module

Creates a custom route table for `managedservice-private-ap-southeast-5a` (`vsw-k1as2atxwl1v5ls0bsgs3`, CIDR `10.151.74.0/24`) and routes `0.0.0.0/0` to the secondary ENI of MikroTik CHR (`eni-k1ahx623o3hwm5j97ubx` / `10.151.74.100`).

## Architecture Flow:
```
Private VM (10.151.74.161)
   └── Default Route (0.0.0.0/0)
         └── Custom Route Table (managedservice-private-rt)
               └── Next-Hop: CHR Private ENI (10.151.74.100 / eni-k1ahx623o3hwm5j97ubx)
                     └── MikroTik CHR Routing / NAT Table
                           └── Egress via CHR Primary EIP (8.215.24.90) -> Internet
```
