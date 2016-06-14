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

  rules = <<EOS
tcp:22,22,ip4:0.0.0.0
EOS
}
```

## Argument Reference

* `rules` - (Required) String
* `display_name` - (Optional) String
* `description` - (Optional) String

## Attributes Reference

* `id` - ID for the security group

## wakamevdc\_ssh\_key

Resource to handle `$api_endpoint/ssh_key_pairs` API.

## Example Usage

```
resource "wakamevdc_ssh_key" "ssh1" {
  display_name = "testkey"
  description = "A generic key for testing purposes"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAm1RVr7PUgF15xm5cE12tuYlwve/F41L+rYXRZllp+7juHUOQj8w8lzmQFMnOyd1jISQ4IK24kX6ysxhWoBZviH6O1mfMWyGdLNqOBx7F8shFDiKJ10aoGoQFY4ZX1oXwDF4NiPAZrE57cqOJCxHidG2Wc1xD//ghWAvVTPVbOqJWb+usJeYfNDrJSjTCvuwOYmbcinMaV6rPOcrAzXQuE8orX2FLnxAJUTXX/TYAbH6HVO3O/XnpDiYH3FKN03YVenufD+gp1pWLuMTqWuwnj7kQ+I2yQw5c5qIYq2GsjHcLVTCRgCEdHX6WlZFVW4jP2XQMU7GrcA+XO69DVQyJHw=="
}
```

## Argument Reference

* `public_key` - (Optional)
* `description` - (Optional)
* `display_name` - (Required)

## Attributes Reference

* `id` - ID for the security group
* `finger_print` - finger print of the ssh key.

## wakamevdc\_network

Resource to handle `$api_endpoint/networks` API.

## Example Usage

```
resource "wakamevdc_network" "net1" {
  ipv4_network = "10.0.0.0"
  prefix = 24
  network_mode = "l2overlay"
  dc_network_name = "vnet"
  display_name = "a new name for me"
  description = "I am a testing network"
  editable = true

  dhcp_range {
    range_begin = "10.0.0.160"
    range_end = "10.0.0.160"
  }

  dhcp_range {
    range_begin = "10.0.0.200"
    range_end = "10.0.0.230"
  }
}
```

## Argument Reference

* `display_name` - (Optional) String
* `description` - (Optional) String
* `ipv4_network` - (Required) String - Network address for the network.
* `prefix` - (Required) String - Netmask bit size for the network.
* `ipv4_gw` - (Optional) String - Default gateway for this network if applicable.
* `metric` - (Optional) Int - IPv4 metric for this network.
* `ip_assignment` - (Optional) String
* `network_mode` - (Required) String - The Wakame-vdc network mode to use.
* `editable` - (Optional) Boolean - Flag that decides if this network can be edited.

* `dc_network_id` - (Optional) String - Wakame-vdc datacenter network id.
* `dc_network_name` - (Optional) String - Wakame-vdc Datacenter network name.

  While both dc\_network\_id and dc\_network\_name are set to optional, it is required to provide one or the other.

* `dhcp_range` - (Optional) TypeSet
  - `range_begin` (Required) String - The start of the DHCP range.
  - `range_end` (Required) String - The end of the DHCP range.

## Attributes Reference

* `id` - ID for the network.

## wakamevdc\_instance

Resource to handle `$api_endpoint/instances` API.

## Example Usage

```
resource "wakamevdc_instance" "web1" {
  display_name = "inst1"
  cpu_cores = 1
  memory_size = 512
  image_id = "wmi-centos1d64"
  hypervisor = "openvz"
  ssh_key_id = "ssh-demo"

  user_data = "joske"

  vif {
    network_id = "nw-demo1"
    security_groups = [
      "sg-10koeien",
      "sg-eenstier",
    ]
  }
}
```

## Argument Reference

* `display_name` - (Optional) String
* `description` - (Optional) String
* `cpu_cores` - (Required) Int - Number of cpu cores.
* `memory_size` - (Required) Int - Memory size in megabytes.
* `hypervisor` - (Required) String - Hypervisor type to run the instance. (kvm, openvz, lxc)
* `image_id` - (Required) String - The image ID to run an instance of.
* `host_node_id` - (Optional) String - HostNode ID to place the instance.
* `ssh_key_id` - (Optional) String - SSH Key ID to install.
* `user_data` - (Optional) String - Arbitrary data that will be accessable form inside the instance

* `vif` - (Optional) TypeSet - Block Section to define network interfaces.
  - `network_id` - (Optional) String - ID of the network to connect this interface to.
  - `ip_address` - (Optional) String - IPv4 address to assign to this network interface.
  - `security_groups` - (Optional) []String - IDs of the security groups to assign to this network interface

## Attributes Reference

* `id` - ID for the instance

# Build & Install

Go (>= 1.6) is required to build with vendored dependencies. Note that it needs to download dependencies using the ``govendor`` tool before running ``go build``. Git is configured not to track *.go sources in ``vendor/`` folder.

```bash
go get -u github.com/kardianos/govendor
go get -u github.com/axsh/wakame-vdc/client/terraform-provider-wakamevdc
cd $GOPATH/src/github.com/axsh/wakame-vdc/client/go-wakamevdc
govendor sync
cd $GOPATH/src/github.com/axsh/wakame-vdc/client/terraform-provider-wakamevdc
govendor sync
go build
```

For installation, simply copy the binary "terraform-provider-wakamevdc" to:

- The location where ``PATH`` variable looks up.
- Add conf to your ``~/.terraformrc`` in ``providers`` block.

Please see [Installing a Plugin](https://www.terraform.io/docs/plugins/basics.html).

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
