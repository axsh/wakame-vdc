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
