package wakamevdc

import (
	"testing"
)

func TestNewClient(t *testing.T) {
	c := NewClient(nil, nil)
	if c == nil {
		t.Errorf("NewClient() failed")
	}
}
