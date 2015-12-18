package wakamevdc

import (
	"fmt"
	"net/url"
	"os"
	"testing"

	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

const testConfig = `
resource "wakamevdc_network" "nw1" {
  ipv4_network = "10.0.0.0"
	prefix = 24
	network_mode = "l2overlay"
	dc_network_id = "%s"
  display_name = "nw1"
}
`

func fetchDCN(name string) (string, error) {
	apiURL, err := url.Parse(os.Getenv("WAKAMEVDC_API_ENDPOINT"))
	if err != nil {
		return "", err
	}
	client := wakamevdc.NewClient(apiURL, nil)
	dcnList, _, _ := client.DCNetwork.List(nil, "vnet")
	return dcnList.Results[0].ID, nil
}

func TestResourceWakamevdcNetworkCreate(t *testing.T) {
	var resourceID string
	dcnID, err := fetchDCN("vnet")
	if err != nil {
		t.Fatalf("Failed to find ID (dcn-xxxx) of \"vnet\" DC Network: %s", err)
	}
	testCheck := func(s *terraform.State) error {
		rs, _ := s.RootModule().Resources["wakamevdc_network.nw1"]
		if rs.Primary.ID == "" {
			return fmt.Errorf("No ID is set")
		}
		resourceID = rs.Primary.ID
		return nil
	}

	testCheckDestroy := func(s *terraform.State) error {
		client := testVdcProvider.Meta().(*wakamevdc.Client)
		_, _, err := client.Network.GetByID(resourceID)
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
				Config: fmt.Sprintf(testConfig, dcnID),
				Check:  testCheck,
			},
		},
	})
}
