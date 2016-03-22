package wakamevdc

import (
	"fmt"
	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
	"testing"
)

//This global variable will be used to track the key's uuid in Wakame-vdc since
//we can't query that from terraform after it's been deleted.
var toBeDeletedKeyID string

func TestResourceWakamevdcSSHKeyCreateUpdateDelete(t *testing.T) {
	testKeyPair := `
resource "wakamevdc_ssh_key" "testkey" {
  display_name = "testkey"
  description = "A generic key for testing purposes"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAm1RVr7PUgF15xm5cE12tuYlwve/F41L+rYXRZllp+7juHUOQj8w8lzmQFMnOyd1jISQ4IK24kX6ysxhWoBZviH6O1mfMWyGdLNqOBx7F8shFDiKJ10aoGoQFY4ZX1oXwDF4NiPAZrE57cqOJCxHidG2Wc1xD//ghWAvVTPVbOqJWb+usJeYfNDrJSjTCvuwOYmbcinMaV6rPOcrAzXQuE8orX2FLnxAJUTXX/TYAbH6HVO3O/XnpDiYH3FKN03YVenufD+gp1pWLuMTqWuwnj7kQ+I2yQw5c5qIYq2GsjHcLVTCRgCEdHX6WlZFVW4jP2XQMU7GrcA+XO69DVQyJHw=="
}
`

	testKeyPairUpdated := `
resource "wakamevdc_ssh_key" "testkey" {
  display_name = "testkeyUpdated"
  description = "Now this needs to change"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAm1RVr7PUgF15xm5cE12tuYlwve/F41L+rYXRZllp+7juHUOQj8w8lzmQFMnOyd1jISQ4IK24kX6ysxhWoBZviH6O1mfMWyGdLNqOBx7F8shFDiKJ10aoGoQFY4ZX1oXwDF4NiPAZrE57cqOJCxHidG2Wc1xD//ghWAvVTPVbOqJWb+usJeYfNDrJSjTCvuwOYmbcinMaV6rPOcrAzXQuE8orX2FLnxAJUTXX/TYAbH6HVO3O/XnpDiYH3FKN03YVenufD+gp1pWLuMTqWuwnj7kQ+I2yQw5c5qIYq2GsjHcLVTCRgCEdHX6WlZFVW4jP2XQMU7GrcA+XO69DVQyJHw=="
}
`

	//Updating the public key will force a new key to be created
	testKeyPairForceNew := `
resource "wakamevdc_ssh_key" "testkey" {
  display_name = "testkeyUpdated"
  description = "Now this needs to change"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA0AE/KL/uhSCZto6YTlNb5rMo/UN7e2qpSBXI0Sb0+lw2VARrTsFNc2+os2WFXgGyFeUULAxhmoZMOAq4k8eOt3+/79pDbWXnvhoAfQCsH6AGMDWZvw6bRwqas3CxZQgl77UWgw54kK6rvFta0m5/sA+c3s9HKxp1SXPTCrCCcTqlYBGAGdJ6boAfOfXpOXqzf1yM2A7X63qArsvhJZeFtKtdfQWEOvz2v1crEZt+1OwTE6H66IJFFj1LbBqQCLeakTyOdKbbw2L8piBDl2Nmuk4QMuHwdJhb8tYiKXOJFytO4lfHLHWSsehMtlKhBTNJnF6dYNMt0pW0pagnfsIglQ=="
}
`
	resource.Test(t, resource.TestCase{
		PreCheck:     nil,
		Providers:    testVdcProviders,
		CheckDestroy: testResourceSshKeyDestroyed,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testKeyPair,
				Check: resource.ComposeTestCheckFunc(
					checkTestKeyCreated(),
					resource.TestCheckResourceAttr(
						"wakamevdc_ssh_key.testkey",
						"fingerprint",
						"38:a5:ff:06:87:10:a5:88:fe:c7:73:9b:7f:9d:bb:9b"),
				),
			},
			resource.TestStep{
				Config: testKeyPairUpdated,
				Check:  checkTestKeyUpdated(),
			},
			resource.TestStep{
				Config: testKeyPairForceNew,
				Check: resource.ComposeTestCheckFunc(
					resource.TestCheckResourceAttr(
						"wakamevdc_ssh_key.testkey",
						"fingerprint",
						"3a:33:75:a6:57:e7:e8:80:df:36:13:b5:8d:8c:e5:69"),
					checkForcedNew(),
				),
			},
		},
	})
}

func getTerraformResourceAndWakameKey(s *terraform.State, resourceName string) (*terraform.ResourceState, *wakamevdc.SshKey, error) {
	rs, ok := s.RootModule().Resources[resourceName]
	if !ok {
		return nil, nil, fmt.Errorf("Not found: %s", resourceName)
	}

	client := testVdcProvider.Meta().(*wakamevdc.Client)

	key, _, err := client.SshKey.GetByID(rs.Primary.ID)

	return rs, key, err
}

func checkForcedNew() resource.TestCheckFunc {
	return func(s *terraform.State) error {
		client := testVdcProvider.Meta().(*wakamevdc.Client)
		oldKey, _, err := client.SshKey.GetByID(toBeDeletedKeyID)
		if err != nil {
			return err
		}

		if oldKey.DeletedAt == "" {
			return fmt.Errorf("Ssh key wasn't deleted when trying to update its public key")
		}

		rs, newKey, err := getTerraformResourceAndWakameKey(s, "wakamevdc_ssh_key.testkey")
		if err != nil {
			return err
		}

		toBeDeletedKeyID = newKey.ID

		if newKey.PublicKey != rs.Primary.Attributes["public_key"] {
			return parameterCheckFailed("public_key",
				newKey.PublicKey,
				rs.Primary.Attributes["public_key"])
		}

		return nil
	}
}

func checkTestKeyUpdated() resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, key, err := getTerraformResourceAndWakameKey(s, "wakamevdc_ssh_key.testkey")
		if err != nil {
			return err
		}

		if key.Description != rs.Primary.Attributes["description"] {
			return parameterCheckFailed("description",
				key.Description,
				rs.Primary.Attributes["description"])
		}

		if key.DisplayName != rs.Primary.Attributes["display_name"] {
			return parameterCheckFailed("display_name",
				key.DisplayName,
				rs.Primary.Attributes["display_name"])
		}

		return nil
	}
}

func checkTestKeyCreated() resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, key, err := getTerraformResourceAndWakameKey(s, "wakamevdc_ssh_key.testkey")
		if err != nil {
			return err
		}

		if key.ID != rs.Primary.ID {
			return parameterCheckFailed("id", key.ID, rs.Primary.ID)
		}

		if key.Description != rs.Primary.Attributes["description"] {
			return parameterCheckFailed("description",
				key.Description,
				rs.Primary.Attributes["description"])
		}

		if key.DisplayName != rs.Primary.Attributes["display_name"] {
			return parameterCheckFailed("display_name",
				key.DisplayName,
				rs.Primary.Attributes["display_name"])
		}

		if key.PublicKey != rs.Primary.Attributes["public_key"] {
			return parameterCheckFailed("public_key",
				key.PublicKey,
				rs.Primary.Attributes["public_key"])
		}

		// We store the test key id in a global variable so we can check if it's properly deleted later.
		toBeDeletedKeyID = key.ID

		return nil
	}
}

func testResourceSshKeyDestroyed(s *terraform.State) error {
	client := testVdcProvider.Meta().(*wakamevdc.Client)

	key, _, err := client.SshKey.GetByID(toBeDeletedKeyID)

	if key.DeletedAt == "" {
		return fmt.Errorf("Ssh key wasn't deleted after 'terraform destroy'")
	}

	return err
}
