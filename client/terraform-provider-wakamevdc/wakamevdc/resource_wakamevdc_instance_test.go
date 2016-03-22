package wakamevdc

import (
	"fmt"
	"strconv"
	"testing"

	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

const testInstanceConfig1 = `
resource "wakamevdc_instance" "inst1" {
  display_name = "inst1"
  cpu_cores = 1
  memory_size = 512
  image_id = "wmi-centos1d64"
  hypervisor = "openvz"
  ssh_key_id = "ssh-demo"

  vif {
    network_id = "nw-demo1"
  }
}
`

func TestResourceWakamevdcInstanceCreate(t *testing.T) {
	var resourceID string

	testCheck := func(s *terraform.State) error {
		rs, inst, err := getTerraformResourceAndWakameInstance(s, "wakamevdc_instance.inst1")
		if err != nil {
			return err
		}

		if inst.ID != rs.Primary.ID {
			return parameterCheckFailed("id", inst.ID, rs.Primary.ID)
		}

		instCPUCoresS := strconv.Itoa(inst.CPUCores)
		if instCPUCoresS != rs.Primary.Attributes["cpu_cores"] {
			return parameterCheckFailed("cpu_cores", instCPUCoresS, rs.Primary.Attributes["cpu_cores"])
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
				Config: testInstanceConfig1,
				Check:  testCheck,
			},
		},
	})
}

func getTerraformResourceAndWakameInstance(s *terraform.State, resourceName string) (*terraform.ResourceState, *wakamevdc.Instance, error) {
	rs, ok := s.RootModule().Resources[resourceName]
	if !ok {
		return nil, nil, fmt.Errorf("Not found: %s", resourceName)
	}

	client := testVdcProvider.Meta().(*wakamevdc.Client)

	key, _, err := client.Instance.GetByID(rs.Primary.ID)
	return rs, key, err
}
