package wakamevdc

import (
	"fmt"
	"testing"

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
	testCheck := func(s *terraform.State) error {
		rs, _ := s.RootModule().Resources["wakamevdc_security_group.sg1"]
		if rs.Primary.ID == "" {
			return fmt.Errorf("No ID is set")
		}
		return nil
	}

	testCheckDestroy := func(s *terraform.State) error {

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
