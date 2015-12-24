provider "wakamevdc" {
  api_endpoint = "http://localhost:9001/api/12.03/"
}

resource "wakamevdc_network" "nw1" {
  display_name = "nw1"
  ipv4_network = "10.0.0.0"
  prefix = 24
  network_mode = "l2overlay"
  dc_network_name = "vnet"
  display_name = "nw1"
}