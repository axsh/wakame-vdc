# Custom instances api

To create a custom instance api call, add the following parameter to the standard instances api.

* "custom"="true"

The request will go through all of the standard error checks that are usually there when starting an instance. Then it will bypass the schedulers if certain other parameters are present.

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

### Custom flag

* custom

This flag must be set to "true" for a custom instance to be run

### Vifs parameter

* vifs

The vifs parameter requires a few extra fields now. Example:

    { eth0 => {"index" => "0", "network_id"=>"nw-demo1", "ip_addr" => "192.168.2.11", "nat_network_id" => "nw-demo2", "nat_ip_addr" => "192.168.3.64", "mac_addr" => "52540028A533" } }

#### Behavior

If the ip_addr field is present, the network scheduler will be bypassed and the ip provided will be assigned to the vnic.

If the mac_addr field is present, the mac address scheduler will be bypassed and the mac address provided will be assigned to the vnic.

If any of the above fields are missing, the respective schedulers defined in dcmgr.conf will be called.

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