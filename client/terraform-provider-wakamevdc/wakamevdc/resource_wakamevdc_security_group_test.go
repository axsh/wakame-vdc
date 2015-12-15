package wakamevdc

import (
	"fmt"
	"testing"

	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

const testEmptyRuleConfig = `
resource "wakamevdc_security_group" "sg1" {
  display_name = "sg1"
  rules = ""
}
`

func TestResourceWakamevdcSecurityGroupCreate(t *testing.T) {
	var resourceID string

	testCheck := func(s *terraform.State) error {
		rs, _ := s.RootModule().Resources["wakamevdc_security_group.sg1"]
		if rs.Primary.ID == "" {
			return fmt.Errorf("No ID is set")
		}
		resourceID = rs.Primary.ID
		return nil
	}

	testCheckDestroy := func(s *terraform.State) error {
		client := testVdcProvider.Meta().(*wakamevdc.Client)
		_, _, err := client.SecurityGroup.GetByID(resourceID)
		if _, ok := err.(*wakamevdc.APIError); ok == false {
			return fmt.Errorf("APIError is expected")
		}
		return nil
	}

	resource.Test(t, resource.TestCase{
		PreCheck:     nil,
		Providers:    testVdcProviders,
		CheckDestroy: testCheckDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testEmptyRuleConfig,
				Check:  testCheck,
			},
		},
	})
}
