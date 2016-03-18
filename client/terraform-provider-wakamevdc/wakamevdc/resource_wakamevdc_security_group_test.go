package wakamevdc

import (
	"fmt"
	"testing"

	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

const testConfigSGMinimal = `
resource "wakamevdc_security_group" "sg1" {
  display_name = "sg1"
}
`

func TestResourceWakamevdcSecurityGroupMinimal(t *testing.T) {
	var resourceID string

	testCheck := func(s *terraform.State) error {
		rs, _ := s.RootModule().Resources["wakamevdc_security_group.sg1"]
		if rs.Primary.ID == "" {
			return fmt.Errorf("No ID is set")
		}
		resourceID = rs.Primary.ID
		return nil
	}

	resource.Test(t, resource.TestCase{
		PreCheck:     nil,
		Providers:    testVdcProviders,
		CheckDestroy: testCheckDestroy(resourceID),
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testConfigSGMinimal,
				Check:  testCheck,
			},
		},
	})
}

const testConfigSGCreate = `
resource "wakamevdc_security_group" "sg2" {
	display_name = "sg2"
	account_id = "a-shpoolxx"
	description = "The second group in our test"
	rules = <<EOS
tcp:22,22,ip4:0.0.0.0
icmp:-1,-1,ip4:0.0.0.0
EOS
}
`

const testConfigSGUpdate = `
resource "wakamevdc_security_group" "sg2" {
	display_name = "sg2 updated"
	account_id = "a-shpoolxx"
	description = "The second updated group in our test"
	rules = <<EOS
udp:53,53,ip4:192.168.3.10/32
EOS
}
`

func TestResourceWakamevdcSecurityGroupFull(t *testing.T) {
	var resourceID string

	testCreated := func(s *terraform.State) error {
		rs, secGroup, err := getTerraformResourceAndWakameSecurityGroup(s, "wakamevdc_security_group.sg2")
		if err != nil {
			return err
		}

		if secGroup.ID != rs.Primary.ID {
			return parameterCheckFailed("id", secGroup.ID, rs.Primary.ID)
		}

		resourceID = secGroup.ID

		if secGroup.DisplayName != rs.Primary.Attributes["display_name"] {
			return parameterCheckFailed("display_name",
				secGroup.DisplayName,
				rs.Primary.Attributes["display_name"])
		}

		if secGroup.AccountID != rs.Primary.Attributes["account_id"] {
			return parameterCheckFailed("account_id",
				secGroup.AccountID,
				rs.Primary.Attributes["account_id"])
		}

		if secGroup.Description != rs.Primary.Attributes["description"] {
			return parameterCheckFailed("description",
				secGroup.Description,
				rs.Primary.Attributes["description"])
		}

		if secGroup.Rules != rs.Primary.Attributes["rules"] {
			return parameterCheckFailed("rules",
				secGroup.Rules,
				rs.Primary.Attributes["rules"])
		}

		return nil
	}

	// The code to check attributes after creation and updating is the same
	testUpdated := testCreated

	resource.Test(t, resource.TestCase{
		PreCheck:     nil,
		Providers:    testVdcProviders,
		CheckDestroy: testCheckDestroy(resourceID),
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testConfigSGCreate,
				Check:  testCreated,
			},
			resource.TestStep{
				Config: testConfigSGUpdate,
				Check:  testUpdated,
			},
		},
	})
}

//helpers
func getTerraformResourceAndWakameSecurityGroup(s *terraform.State, resourceName string) (*terraform.ResourceState, *wakamevdc.SecurityGroup, error) {
	rs, ok := s.RootModule().Resources[resourceName]
	if !ok {
		return nil, nil, fmt.Errorf("Not found: %s", resourceName)
	}

	client := testVdcProvider.Meta().(*wakamevdc.Client)
	securityGroup, _, err := client.SecurityGroup.GetByID(rs.Primary.ID)

	return rs, securityGroup, err
}

func testCheckDestroy(uuid string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		client := testVdcProvider.Meta().(*wakamevdc.Client)

		_, _, err := client.SecurityGroup.GetByID(uuid)
		if _, ok := err.(*wakamevdc.APIError); ok == false {
			return fmt.Errorf("The security group resource wasn't deleted when expected")
		}

		return nil
	}
}
