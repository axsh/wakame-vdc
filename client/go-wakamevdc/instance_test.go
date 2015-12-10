package wakamevdc

import (
	"testing"
)

func TestInstance(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Instance == nil {
		t.Errorf("InstanceService should not be nil")
	}
}

func TestInstanceList(t *testing.T) {
	c := NewClient(nil, nil)

	var instList *InstancesList

	instList, _, _ = c.Instance.List(nil)

	instList, _, _ = c.Instance.List(&ListRequestParams{
		Start: 1,
		Limit: 1,
	})
	if !(len(instList.Results) <= instList.Limit) {
		t.Errorf("Results contain more items than specifed in limit")
	}
}
