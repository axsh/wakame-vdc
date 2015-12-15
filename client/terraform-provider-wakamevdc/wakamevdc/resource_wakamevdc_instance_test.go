package wakamevdc

import (
	"fmt"
	"testing"

	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

const testInstanceConfig = `
resource "wakamevdc_instance" "inst1" {
  display_name = "sg1"
  cpu_cores = 1
  memory_size = 512
  image_id = "wmi-centos1d64"
  hypervisor = "openvz"
}
`

func TestResourceWakamevdcInstanceCreate(t *testing.T) {
	var resourceID string

	testCheck := func(s *terraform.State) error {
		rs, _ := s.RootModule().Resources["wakamevdc_instance.inst1"]
		if rs.Primary.ID == "" {
			return fmt.Errorf("No ID is set")
		}
		if rs.Primary.Attributes["state"] != "running" {
			return fmt.Errorf("instance is in unexpected state: %s", rs.Primary.ID)
		}
		resourceID = rs.Primary.ID
		return nil
	}

	testCheckDestroy := func(s *terraform.State) error {
		client := testVdcProvider.Meta().(*wakamevdc.Client)

		inst, _, err := client.Instance.GetByID(resourceID)
		if err != nil {
			return err
		}
		if inst.State != "terminated" {
			return fmt.Errorf("instance is in unexpected state: %s", resourceID)
		}
		return nil
	}

	resource.Test(t, resource.TestCase{
		PreCheck:     nil,
		Providers:    testVdcProviders,
		CheckDestroy: testCheckDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testInstanceConfig,
				Check:  testCheck,
			},
		},
	})
}
