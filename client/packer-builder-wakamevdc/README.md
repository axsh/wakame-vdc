# Wakame-vdc Builder

Type: ``wakamevdc``

## Basic Example

``` {.javascript}
{
  "builders": [
    {
      "type": "wakamevdc",
      "image_id": "wmi-centos1d64",
      "api_endpoint": "http://localhost:9001/api/12.03/",
      "account_id": "a-00001",
      "hypervisor": "openvz",
      "cpu_cores": 1,
      "memory_size": 1024,
      "network_id": "nw-demo1"
    }
  ]
}
```

### Required:

- `image_id` (string) - Wakame Image ID to source.
- `network_id` (string) - Network ID (nw-xxxx) to attach interface.
- `hypervisor` (string) - Choose Hypervisor type: openvz, lxc, kvm

### Optional:

- `api_endpoint` (string) - Base URL to  the Web API. (default: ``http://localhost:9001/api/12.03/``)
- `cpu_cores` (int) Number CPU cores for the instance. (Default: 1)
- `memory_size` (int) Memory size for the instance in megabyte. (Default: 512MB)
- `account_id` (string) - Account ID to become owner for new image (Default: a-shpoolxx)
- `host_node_id` (string) - Host Node ID to run instance.
- `user_data` (string) - User data for the instance.
- `state_timeout` (string) - Duration in seconds to wait for instance's state transition. (Default: 360)
- `ssh_username` (string) - User name for SSH connection. (Default: root)
- `backup_storage_id` (string) - Backup Storage ID (bkst-xxxx) to upload image file. (Default: same storage)

## Build & Install

Once you complete to build, you'll see the ``packer-builder-wakamevdc`` binary. It can be installed to:

- Same folder where ``packer`` is in.
- ``$HOME/.packer.d/plugins``
- Current working directory

See [Installing Plugins](https://www.packer.io/docs/extend/plugins.html) section.
