package wakamevdc

import (
	"testing"
)

func TestDCNetwork(t *testing.T) {
	c := NewClient(nil, nil)

	if c.DCNetwork == nil {
		t.Errorf("DCNetworkService should not be nil")
	}
}

func TestDCNetworkList(t *testing.T) {
	c := NewClient(nil, nil)

	var imgList *DCNetworksList

	imgList, _, _ = c.DCNetwork.List(nil, "")

	imgList, _, _ = c.DCNetwork.List(&ListRequestParams{
		Start: 1,
		Limit: 1,
	}, "")
	if !(len(imgList.Results) <= imgList.Limit) {
		t.Errorf("Results contain more items than specifed in limit")
	}
}
