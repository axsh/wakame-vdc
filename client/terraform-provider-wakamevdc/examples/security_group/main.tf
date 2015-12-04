provider "wakamevdc" {
  api_endpoint = "http://localhost:9001/api/12.03/"
}

resource "wakamevdc_security_group" "sg1" {
  display_name = "sg1"
  rules = "tcp:22,22,ip4:0.0.0.0"
}
