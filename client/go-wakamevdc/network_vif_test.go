package wakamevdc

import (
	"testing"
)

func TestNetworkVif(t *testing.T) {
	c := NewClient(nil, nil)

	if c.NetworkVif == nil {
		t.Errorf("NetworkVifService should not be nil")
	}
}

func TestNetworkVifList(t *testing.T) {
	c := NewClient(nil, nil)

	_, _, err := c.NetworkVif.List(nil)
	if err != nil {
		t.Errorf("API call failed: %v", err)
	}
}
