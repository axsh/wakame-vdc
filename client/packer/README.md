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
