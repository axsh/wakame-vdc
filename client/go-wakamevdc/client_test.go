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

func TestSetAccount(t *testing.T) {
	c := NewClient(nil, nil)
	if c.accountID != defaultAccountID {
		t.Errorf("accountID does not have default value:")
	}

	c.AccountID("a-000001")
	if c.accountID != "a-000001" {
		t.Errorf("AccountID() failed to overwrite")
	}
}
