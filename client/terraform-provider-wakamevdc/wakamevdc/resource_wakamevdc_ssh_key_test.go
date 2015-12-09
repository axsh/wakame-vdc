package wakamevdc

import (
	"fmt"
	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
	"testing"
)

const testKeyPair = `
resource "wakamevdc_ssh_key" "testkey" {
  display_name = "testkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAm1RVr7PUgF15xm5cE12tuYlwve/F41L+rYXRZllp+7juHUOQj8w8lzmQFMnOyd1jISQ4IK24kX6ysxhWoBZviH6O1mfMWyGdLNqOBx7F8shFDiKJ10aoGoQFY4ZX1oXwDF4NiPAZrE57cqOJCxHidG2Wc1xD//ghWAvVTPVbOqJWb+usJeYfNDrJSjTCvuwOYmbcinMaV6rPOcrAzXQuE8orX2FLnxAJUTXX/TYAbH6HVO3O/XnpDiYH3FKN03YVenufD+gp1pWLuMTqWuwnj7kQ+I2yQw5c5qIYq2GsjHcLVTCRgCEdHX6WlZFVW4jP2XQMU7GrcA+XO69DVQyJHw=="
}
`

func TestResourceWakamevdcSSHKeyCreate(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     nil,
		Providers:    testVdcProviders,
		CheckDestroy: testResourceSshKeyDestroyed,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testKeyPair,
				Check:  checkTestKeyCreated(),
			},
		},
	})
}

func checkTestKeyCreated() resource.TestCheckFunc {
	return func(s *terraform.State) error {
		resource_name := "wakamevdc_ssh_key.testkey"
		rs, ok := s.RootModule().Resources[resource_name]

		if !ok {
			return fmt.Errorf("Not found: %s", resource_name)
		}

		client := testVdcProvider.Meta().(*wakamevdc.Client)

		key, _, err := client.SshKey.GetByID(rs.Primary.ID)
		if err != nil {
			return err
		}

		if key.ID != rs.Primary.ID {
			return fmt.Errorf("Ssh key had the wrong id. Expected %s, Got %s", key.ID, rs.Primary.ID)
		}

		return nil
	}
}

func testResourceSshKeyDestroyed(s *terraform.State) error {
	client := testVdcProvider.Meta().(*wakamevdc.Client)

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "wakamevdc_ssh_key" {
			continue
		}

		_, _, err := client.SshKey.GetByID(rs.Primary.ID)
		if err == nil {
			return fmt.Errorf("Ssh Key still exists")
		}
	}

	return nil
}
