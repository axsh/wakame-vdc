# Custom instances api

To specify a host node for an api simply add the following parameter to the api call.

* host_node_id=<hostnode_id?

To specify an ip address, add the key to the "vifs" parameter

* { eth0 => {"ipv4_addr" => "192.168.2.11", mac_addr="52540028A533" } }

The request will go through all of the standard error checks that are usually there when starting an instance. Then it will call specific schedulers to handle these assignments.

## url

POST http://<ip address>:9001/api/12.03/instances

## Parameters

### Standard prameters

* image_id
* cpu-cores
* user_data
* ssh_key_id
* ha_enabled
* display_name
* memory_size

### Vifs parameter

* vifs

The vifs parameter requires a few extra fields now. Example:

    { eth0 => {"index" => "0", "network_id"=>"nw-demo1", "ipv4_addr" => "192.168.2.11", "nat_network_id" => "nw-demo2", "nat_ipv4_addr" => "192.168.3.64", "mac_addr" => "52540028A533" } }

It is currently not possible to specify the ip for one nic and not specify it for another. When you specify an ip for one nic, you have to specify both ip and mac address for them all.

The keys "nat_network_id" and "nat_ipv4_addr" are optional.

#### Errors

* 400 InvalidMacAddress

Raise when the mac address provided is not a valid mac address.

* 400 DuplicateMacAddress

Raise when the mac address provided is already in use.

* 404 UnknownNetwork

Raise when the network id provided does not exist in the database.

* 400 DuplicateIPAddress

Raise when the ip address provided is already in use or when the nat ip address provided is already in use.

* 400 InvalidIPAddress

Raise when the ip address provided is not a valid ip address.

* 400 IPAddressNotPartOfSegment

Raise when the ip address provided is not part of the network segment described by network_id.

* 400 MacNotInRange

Raise when the specified mac address does not exist in any range defined in the database.

* 400 IpNotInDhcpRange

Raise when the specified ip does not exist in the dhcp range specify for its network.

### Host node parameter

* host_node_id

#### Behavior

This parameter decides the host node to start the custom instance in.

If it is omitted, the host node scheduler defined in dcmgr.conf will be called.

#### Errors

* 404 UnknownHostNode

Raise when the host node id provided doesn't exist on the database

* 400 OutOfHostCapacity

Raise when the host node provided doesn't have the capacity to start this instance.