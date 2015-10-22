# Networking


## Configure Wakame-vdc to run the instance with second interface

Currently, HVA node has single bridge ``br1`` which is used to attach the
virtual interface on each instance.

We are going to setup following parameters to the Wakame-vdc cluster.

| ------------------------ | ----------- |
| Bridge Interface Name    | br2         |
| DC Network               | internal    |
| Network                  | nw-internal |

Define DC Network on database.

```
$ /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage network dc add internal
dcn-ny2jujaz
```

On HVA host(s), we have to setup new Linux bridge ``br2`` to plug instance virtual NIC.

```
$ cat /etc/sysconfig/network-scripts/ifcfg-br2
DEVICE=br2
TYPE=Bridge
BOOTPROTO=static
IPADDR=10.2.0.1
NETMASK=255.255.255.0
NETWORK=10.2.0.0
ONBOOT=yes
$ sudo ifup br2
$ ip addr show dev br2
10: br2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN
    link/ether ce:a4:b9:34:9a:e3 brd ff:ff:ff:ff:ff:ff
    inet 10.2.0.1/24 brd 10.2.0.255 scope global br2
    inet6 fe80::cca4:b9ff:fe34:9ae3/64 scope link
       valid_lft forever preferred_lft forever
$ ping 10.2.0.1
PING 10.2.0.1 (10.2.0.1) 56(84) bytes of data.
64 bytes from 10.2.0.1: icmp_seq=1 ttl=64 time=0.083 ms
64 bytes from 10.2.0.1: icmp_seq=2 ttl=64 time=0.069 ms
64 bytes from 10.2.0.1: icmp_seq=3 ttl=64 time=0.066 ms
```

Edit ``/etc/wakame-vdc/hva.conf`` to have ``internal`` dc network definition.

```
dc_network('internal') {
  bridge_type 'linux'
  interface 'eth0'
  bridge 'br2'
}
```

Let hva process reload hva.conf.

```
$ sudo initctl restart vdc-hva
```


Define network ``nw-internal`` 10.2.0.0/24 (.10 - .100).

```
$ /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage network add --ipv4-network=10.2.0.0 --prefix=24 --uuid=internal
nw-internal
$ /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage network dhcp addrange nw-internal 10.2.0.10 10.2.0.100
$ /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage network show nw-internal
UUID: nw-internal
Name:
Network Mode: securitygroup
Service Type: std
Metric: 100
IPv4:
  Network address: 10.2.0.0/24
  Gateway address:
DHCP Information:
  DHCP Server:
  DNS Server:
Bandwidth:
  unlimited
```

Associate network to dc network.

```
$ /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage network forward nw-internal internal
```



Create new instance equips two network interfaces.

```
$ cat vifs.txt
{"eth0": {"network": "nw-demo1"}, "eth1": {"network": "nw-internal"}}
$ mussel instance create --cpu-cores=1 --memmory-size=256 --vifs=./vifs.txt
---
:id: i-sf561prj
:account_id: a-shpoolxx
:host_node:
:cpu_cores: 1
:memory_size: 256
:arch: x86_64
:image_id: wmi-centos1d64
....
$ mussel instance show i-sf561prj
---
:id: i-sf561prj
:account_id: a-shpoolxx
:host_node: hn-1box64
:cpu_cores: 1
:memory_size: 256
:arch: x86_64
:image_id: wmi-centos1d64
:created_at: 2015-10-21 09:37:00.000000000 Z
:updated_at: 2015-10-21 09:37:00.000000000 Z
:terminated_at:
:deleted_at:
:state: initializing
:status: init
:ssh_key_pair:
:volume:
- :vol_id: vol-kmrkqdps
  :state: pending
:vif:
- :vif_id: vif-7mjok6mv
  :network_id: nw-demo1
  :ipv4:
    :address: 10.0.2.100
    :nat_address:
  :security_groups: []
- :vif_id: vif-qiy4qbtx
  :network_id: nw-internal
  :ipv4:
    :address: 10.2.0.10
    :nat_address:
  :security_groups: []
:hostname: sf561prj
:ha_enabled: 0
:hypervisor: openvz
:display_name: ''
:service_type: std
:monitoring:
  :enabled: false
  :mail_address: []
  :items: {}
:labels:
- :resource_uuid: i-sf561prj
  :name: monitoring.enabled
  :value_type: 1
  :value: 'false'
  :created_at: 2015-10-21 09:37:00.000000000 Z
  :updated_at: 2015-10-21 09:37:00.000000000 Z
:boot_volume_id: vol-kmrkqdps
```


You can verify that ``vif-qiy4qbtx`` is attached to ``br2`` on HVA host.

```
$ brctl show br2
bridge name     bridge id               STP enabled     interfaces
br2             8000.001851890c7e       no              vif-qiy4qbtx
```
