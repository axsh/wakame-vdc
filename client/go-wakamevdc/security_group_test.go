package wakamevdc

import (
	"testing"
)

func TestSecurityGroup(t *testing.T) {
	c := NewClient(nil, nil)

	if c.SecurityGroup == nil {
		t.Errorf("SecurityGroup should not be nil")
	}
}

func TestSecurityGroupList(t *testing.T) {
	c := NewClient(nil, nil)

	var sgList *SecurityGroupsList

	sgList, _, _ = c.SecurityGroup.List(nil)

	sgList, _, _ = c.SecurityGroup.List(&ListRequestParams{
		Start: 1,
		Limit: 1,
	})
	if !(len(sgList.Results) <= sgList.Limit) {
		t.Errorf("Results contain more items than specifed in limit")
	}
}
