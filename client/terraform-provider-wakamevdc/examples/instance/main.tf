provider "wakamevdc" {
  api_endpoint = "http://10.0.2.15:9001/api/12.03/"
}

resource "wakamevdc_instance" "inst1" {
  cpu_cores = 1
  memory_size = 512
  hypervisor = "openvz"
  image_id = "wmi-centos1d64"
  display_name = "inst1"
  host_node_id = "hn-1box64"

  vif {
    network_id = "nw-demo1"
    ip_address = "10.0.2.135"
    security_groups = ["sg-1p9i5re6", "sg-bzz0kesk"]
  }
}
