# Wakame-vdc Provider

## Example Usage

```
# Configure the Wakame-vdc provider
provider "wakamevdc" {
  api_endpoint = "http://localhost:9001/api/12.03/"
  account_id = "a-shpoolx"
}

# Create an instance
resource "wakamevdc_instance" "www" {
    ...
}
```

## Argument Reference

The following arguments are supported:

* `api_endpoint` - (Required) The URL to the Wakame-vdc API endpoint.
* `account_id` - (Required) Default account ID to perform resource operations.

## wakamevdc\_security\_group

Resource to handle `$api_endpoint/security_groups` API.

## Example Usage

```
resource "wakamevdc_security_group" "sg1" {
  description = "Allow SSH port"
  display_name = "sg1"

  rules = [
    "ip4,0.0.0.0,22"
  ]
}
```

## Argument Reference

* `rules` - (Required) String or Array representation.
* `display_name` - (Optional)
* `description` - (Optional)

## Attributes Reference

* `id` - ID for the security group

## wakamevdc\_ssh\_key

Resource to handle `$api_endpoint/ssh_key_pairs` API.

## Example Usage

```
resource "wakamevdc_ssh_key" "ssh1" {
  description = "Allow SSH port"
  display_name = "ssh1"
  public_key = "${file(./id_rsa)}"
}
```

## Argument Reference

* `public_key` - (Optional)
* `description` - (Optional)
* `display_name` - (Optional)

## Attributes Reference

* `id` - ID for the security group
* `finger_print` - finger print of the ssh key.

## wakamevdc\_network

Resource to handle `$api_endpoint/networks` API.

## Example Usage

```
resource "wakamevdc_network" "net1" {
  description = "Demo network"
  display_name = "net1"
  network = "192.168.0.0"
  prefix = 24
  dc_network = "public"
}
```

## Argument Reference

* `network` - (Required) Network address for the network.
* `prefix` - (Required) Netmask bit size for the network.
* `dc_network` - (Required) L2 segment name.
* `description` - (Optional)
* `display_name` - (Optional)

## Attributes Reference

* `id` - ID for the network.

## wakamevdc\_instance

Resource to handle `$api_endpoint/instances` API.

## Example Usage

```
resource "wakamevdc_instance" "web1" {
  cpu_cores = 1
  memory_size = 512
  hypervisor = "kvm"
  image_id = "wmi-centos7"
  host_node_id = "hn-kvm1"

  description = "My web server"
  display_name = "web1"
  user_data = <<END
#!/bin/sh
echo "Started"
END

  vif {
    network_id = "nw-pub"
    ip_address = "192.168.1.10"
  }
  local_volume {
    volume_size = 1024
  }
  shared_volume {
    backup_object_id = "bo-xxxxx"
  }
}
```

## Argument Reference

* `cpu_cores` - (Required) Number of vcpu cores.
* `memory_size` - (Required) Memory size in megabytes.
* `hypervisor` - (Required) Hypervisor type to run the instance. (kvm, openvz, lxc)
* `image_id` - (Required) The image ID to run the instance.
* `host_node_id` - (Optional) HostNode ID to place the instance.
* `ssh_key_id` - (Optional) SSH Key ID to install.
* `vif` - (Optional) Block Section to define network interfaces. See [Network Interfaces](#network-interfaces).
* `local_volume` - (Optional) See [Block Devices](#block-devices).
* `shared_volume` - (Optional) See [Block Devices](#block-devices).
* `display_name` - (Optional)
* `description` - (Optional)
* `user_data` - (Optional)

<a id="block-devices"></a>
## Block Devices

`local_volume` and `shared_volume` take set of parameters to attach the volume
for the instance at booting. `local_volume`

Either `volume_size` or `backup_object_id` needs to be set. The `volume_size` creates
a blank volume with the size. The `backup_object_id` creates the new volume with
same data.

Parameters in the `local_volume` section:

* `volume_size` - (Optional) The size of the volume in megabytes.
* `backup_object_id` - (Optional) The disk image data to copy

Parameters in the `shared_volume` section:

* `volume_size` - (Optional) The size of the volume in megabytes.
* `backup_object_id` - (Optional) The source disk image to copy.
* `storage_node_id` - (Optional) The storage node ID.

<a id="network-interfaces"></a>
## Network Interfaces

``vif`` section manages the attrubites for the network interface.

* `network_id` - (Required) The network to join the interface.
* `ip_address` - (Optional) IP address for the interface.
* `security_group_id` - (Optional) Security group ID to join.

## Attributes Reference

* `id` - ID for the instance

# Testing the provider

In this section we'll briefly explain how to run the tests included with the provider.

The terraform test framework requires the `TF_ACC` environment variable to be set or all tests will be skipped. This is to avoid running the tests accidentally and creating real resources in the process.

```
export TF_ACC="some value"
```

The tests also require an actual working Wakame-vdc to be set up and running. The following environment variable needs to be set for the tests to know where to send Wakame-vdc api requests. Make sure the trailing slash is included. The tests will not work otherwise.

```
export WAKAMEVDC_API_ENDPOINT="http://192.168.3.100:9001/api/12.03/"
```

Finally, terraform's test framework requires the `-v` flag to be set when running its tests.

```
cd /path/to/wakame-vdc/client/terraform-provider-wakamevdc/wakamevdc
go test -v
```
