provider "wakamevdc" {
  api_endpoint = "http://localhost:9001/api/12.03/"
}

resource "wakamevdc_ssh_key" "ssh1" {
  display_name = "ssh1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAm1RVr7PUgF15xm5cE12tuYlwve/F41L+rYXRZllp+7juHUOQj8w8lzmQFMnOyd1jISQ4IK24kX6ysxhWoBZviH6O1mfMWyGdLNqOBx7F8shFDiKJ10aoGoQFY4ZX1oXwDF4NiPAZrE57cqOJCxHidG2Wc1xD//ghWAvVTPVbOqJWb+usJeYfNDrJSjTCvuwOYmbcinMaV6rPOcrAzXQuE8orX2FLnxAJUTXX/TYAbH6HVO3O/XnpDiYH3FKN03YVenufD+gp1pWLuMTqWuwnj7kQ+I2yQw5c5qIYq2GsjHcLVTCRgCEdHX6WlZFVW4jP2XQMU7GrcA+XO69DVQyJHw=="
}

