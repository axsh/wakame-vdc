# IP Pool and NAT

## Acquire and Release IP address handle from IP Pool

Confirm that the IP Pool is assigned to ``dc_network``. ``dc_network`` has to be
assigned to the IP Pool object.

```
$ mussel ip_pool show ipp-external
---
:id: ipp-external
:display_name: external ips
:created_at: 2015-10-19 23:32:04.000000000 Z
:updated_at: 2015-10-19 23:32:04.000000000 Z
:dc_networks:
- :id: dcn-nmcbsyp6
  :name: public
  :description: ''
  :created_at: 2015-10-19 23:32:03.000000000 Z
  :updated_at: 2015-10-19 23:32:03.000000000 Z
  :uuid: dcn-nmcbsyp6
  :vlan_lease_id:
  :offering_network_modes:
  - securitygroup
  :allow_new_networks: false

```

Acquire new IP address handle from the IP Pool ``ipp-external``.

```
$ mussel ip_pool acquire ipp-external --network-id=nw-demo1
---
:ip_handle_id: ip-giw3tajk
:dc_network_id: dcn-nmcbsyp6
:network_id: nw-demo1
:ipv4: 10.0.2.100
```

```
$ mussel ip_handle show ip-giw3tajk --network-id nw-demo1
---
:id: ip-giw3tajk
:network: nw-demo1
:network_vif:
:ipv4: 10.0.2.100
:display_name: ''
:created_at: 2015-10-20 23:18:02.000000000 Z
:updated_at: 2015-10-20 23:18:02.000000000 Z
:expires_at:
```

Release IP address handle ``ip-giw3tajk``.

```
$ mussel ip_pool release ipp-external --ip-handle-id=ip-giw3tajk
--- {}
```

### Attach and Detach IP address handle to VIF.

Create an instance to attach the IP address handle ``ip-giw3tajk``.

```
$ mussel instance create --cpu-cores=1 --memory-size=256 --vifs=./vifs.txt 
---
:id: i-w7zhpdxl
:account_id: a-shpoolxx
:host_node:
:cpu_cores: 1
:memory_size: 256
....
```

Find ``vif-xxxx`` that is allocated to the instance ``i-w7zhpdxl``.

```
$ mussel instance show i-w7zhpdxl
---
:id: i-w7zhpdxl
:account_id: a-shpoolxx
:host_node: hn-1box64
...
...
:vif:
- :vif_id: vif-31zxn2al
  :network_id: nw-demo1
  :ipv4:
    :address: 10.0.2.101
    :nat_address:
  :security_groups: []
...
```

Attach IP address handle ``ip-giw3tajk`` to VIF ``vif-31zxn2al``.

```
$ mussel network_vif attach_external_ip vif-31zxn2al --ip-handle-id=ip-giw3tajk 
---
:network_id: nw-demo1
:vif_id: vif-n7s8thwa
:ip_handle_id: ip-giw3tajk
:ipv4: 10.0.2.100
```

Confirm the IP address handle ``ip-giw3tajk`` gets associated to the VIF ``vif-n7s8thwa``.

```
$ mussel ip_handle show ip-giw3tajk
---
:id: ip-giw3tajk
:network: nw-demo1
:network_vif: vif-n7s8thwa
:ipv4: 10.0.2.100
:display_name: ''
:created_at: 2015-10-20 23:18:02.000000000 Z
:updated_at: 2015-10-20 23:18:02.000000000 Z
:expires_at:

```


Detach IP address handle ``ip-giw3tajk`` from VIF.

```
$ mussel network_vif detach_external_ip vif-31zxn2al --ip-handle-id=ip-giw3tajk 
---
- :network_id: nw-demo1
  :vif_id: vif-n7s8thwa
  :ip_handle_id: ip-giw3tajk
  :ipv4: 10.0.2.100
$ mussel ip_handle show ip-giw3tajk
---
:id: ip-giw3tajk
:network: nw-demo1
:network_vif:
:ipv4: 10.0.2.100
:display_name: ''
:created_at: 2015-10-20 23:18:02.000000000 Z
:updated_at: 2015-10-20 23:18:02.000000000 Z
:expires_at:
```
