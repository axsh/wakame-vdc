# Wakame-vdc Builder

Type: ``wakamevdc``

## Basic Example

``` {.javascript}
{
  "builders": [
    {
      "type": "wakamevdc",
      "image_id": "wmi-centos64",
      "api_endpoint": "http://localhost:9001/api/1203",
      "account_id": "a-00001"
    }
  ]
}
```

### Required:

- `image_id` (string) - Wakame Image ID to source.

### Optional:

- `account_id` (string) -

- `api_endpoint` (string) - Base URL for the Web API. (default: ``http://localhost:9001/api/1203``)

## Build & Install

Once you complete to build, you'll see the ``packer-builder-wakamevdc`` binary. It can be installed to:

- Same folder where ``packer`` is in.
- ``$HOME/.packer.d/plugins``
- Current working directory

See [Installing Plugins](https://www.packer.io/docs/extend/plugins.html) section.
