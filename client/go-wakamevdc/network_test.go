package wakamevdc

import (
	"testing"
)

func TestNetwork(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Network == nil {
		t.Errorf("ImageService should not be nil")
	}
}

func TestNetworkList(t *testing.T) {
	c := NewClient(nil, nil)

	var nwList *NetworksList

	nwList, _, _ = c.Network.List(nil)

	nwList, _, _ = c.Network.List(&ListRequestParams{
		Start: 1,
		Limit: 1,
	})
	if !(len(nwList.Results) <= nwList.Limit) {
		t.Errorf("Results contain more items than specifed in limit")
	}
}

func TestNetworkCreate(t *testing.T) {
	c := NewClient(nil, nil)
	// 1box image sets "allow_new_networks" true
	dcnList, _, err := c.DCNetwork.List(nil, "vnet")
	if err != nil {
		t.Fatalf("Failed DCNetwork.List: %v", err)
	}
	if dcnList.Total != 1 {
		t.Fatalf("Unknown DCNetwork name=\"vnet\"")
	}
	nw, _, err := c.Network.Create(&NetworkCreateParams{
		IPv4Network: "10.0.0.0",
		Prefix:      24,
		NetworkMode: "l2overlay",
		DCNetworkID: dcnList.Results[0].ID,
	})
	if err != nil {
		t.Fatalf("Failed to create network: %v", err)
	}

	_, err = c.Network.Delete(nw.ID)
	if err != nil {
		t.Fatalf("Failed to delete network: %s", nw.ID)
	}
}
