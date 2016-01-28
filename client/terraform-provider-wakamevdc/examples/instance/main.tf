provider "wakamevdc" {
  api_endpoint = "http://10.0.2.15:9001/api/12.03/"
}

resource "wakamevdc_instance" "inst1" {
  cpu_cores = 1
  memory_size = 512
  hypervisor = "openvz"
  image_id = "wmi-centos1d64"
  display_name = "inst1"

  vif {
    network_id = "nw-demo1"
  }
}
