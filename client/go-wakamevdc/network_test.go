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

func TestNetworkFull(t *testing.T) {
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
		Editable:    true,
		DCNetworkID: dcnList.Results[0].ID,
	})
	if err != nil {
		t.Fatalf("Failed to create network: %v", err)
	}

	_, err = c.Network.DHCPRangeCreate(nw.ID, &DHCPRangeCreateParams{
		RangeBegin: "10.0.0.20",
		RangeEnd:   "10.0.0.30",
	})
	if err != nil {
		t.Fatalf("Failed to create dhcp range: %v", err)
	}

	dhcpRanges, _, err := c.Network.DHCPRangeList(nw.ID)
	if err != nil {
		t.Fatalf("Failed to query dhcp range: %v", err)
	}

	if len(*dhcpRanges) != 1 {
		t.Fatalf("Got more dhcp ranges than expected. Expected 1, got %d",
			len(*dhcpRanges))
	}

	if (*dhcpRanges)[0][0] != "10.0.0.20" || (*dhcpRanges)[0][1] != "10.0.0.30" {
		t.Fatalf("Unexpected dhcp range. Expected: [[10.0.0.20 10.0.0.30]]. Got: %v",
			*dhcpRanges)
	}

	_, err = c.Network.DHCPRangeDelete(nw.ID, &DHCPRangeDeleteParams{
		RangeBegin: "10.0.0.20",
		RangeEnd:   "10.0.0.30",
	})

	dhcpRanges, _, err = c.Network.DHCPRangeList(nw.ID)
	if err != nil {
		t.Fatalf("Failed to query dhcp range: %v", err)
	}

	if len(*dhcpRanges) != 0 {
		t.Fatalf("Dhcp range didn't get deleted. Expected empty slice. got %v",
			*dhcpRanges)
	}

	_, err = c.Network.Delete(nw.ID)
	if err != nil {
		t.Fatalf("Failed to delete network: %s", nw.ID)
	}
}
