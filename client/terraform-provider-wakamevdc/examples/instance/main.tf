provider "wakamevdc" {
  api_endpoint = "http://localhost:9001/api/12.03/"
}

resource "wakamevdc_instance" "inst1" {
  cpu_cores = 1
  memory_size = 512
  hypervisor = "openvz"
  image_id = "wmi-centos1d64"
  display_name = "inst1"
}