package wakamevdc

import (
	"testing"
)

func TestSshKey(t *testing.T) {
	c := NewClient(nil, nil)

	if c.SshKey == nil {
		t.Errorf("SshKeyService should not be nil")
	}
}

func TestSshKeyList(t *testing.T) {
	c := NewClient(nil, nil)

	var sshkList *SshKeysList

	sshkList, _, _ = c.SshKey.List(nil)

	sshkList, _, _ = c.SshKey.List(&ListRequestParams{
		Start: 1,
		Limit: 1,
	})
	if !(len(sshkList.Results) <= sshkList.Limit) {
		t.Errorf("Results contain more items than specifed in limit")
	}
}
