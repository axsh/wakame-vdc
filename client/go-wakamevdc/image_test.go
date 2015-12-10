package wakamevdc

import (
	"testing"
)

func TestImage(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Image == nil {
		t.Errorf("ImageService should not be nil")
	}
}

func TestImageList(t *testing.T) {
	c := NewClient(nil, nil)

	var imgList *ImagesList

	imgList, _, _ = c.Image.List(nil)

	imgList, _, _ = c.Image.List(&ListRequestParams{
		Start: 1,
		Limit: 1,
	})
	if !(len(imgList.Results) <= imgList.Limit) {
		t.Errorf("Results contain more items than specifed in limit")
	}
}
