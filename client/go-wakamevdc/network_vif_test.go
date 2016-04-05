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
