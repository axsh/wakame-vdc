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


## wakamevdc_security_group

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

* `rules` - (Required)
* `description` - (Optional)


## wakamevdc_instance

## Example Usage

```
resource "wakamevdc_instance" "web1" {
  cpu_cores = 1
  memory_size = 512
  hypervisor = "kvm"
  image_id = "wmi-centos7"

  description = "My web server"
  display_name = "web1"

  vifs = [
    "ip4,0.0.0.0,22"
  ]
}
```

## Argument Reference

* `cpu_cores` - (Required)
* `memory_size` - (Required)
* `hypervisor` - (Required)
* `vifs` - (Optional)
* `volumes` - (Optional)
* `display_name` - (Optional)
* `description` - (Optional)
* `user_data` - (Optional)
