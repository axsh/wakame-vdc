package wakamevdc

import (
	"fmt"
	"net/http"
)

const ImagePath = "images"

type Image struct {
	ID             string `json:"id"`
	Arch           string `json:"arch"`
	BackupObjectID string `json:"backup_object_id"`
	OSType         string `json:"os_type"`
	State          string `json:"state"`
	RootDevice     string `json:"root_device"`
	FileFormat     string `json:"file_format"`
	ParentImageID  string `json:"parent_image_id"`
	DisplayName    string `json:"display_name"`
	Description    string `json:"description"`
	CreatedAt      string `json:"created_at"`
	UpdatedAt      string `json:"updated_at"`
	DeletedAt      string `json:"deleted_at"`
}

type ImageService struct {
	client *Client
}

func (s *ImageService) Delete(id string) (*http.Response, error) {
	return trapAPIError(func(apiErr *APIError) (*http.Response, error) {
		return s.client.Sling().Delete(fmt.Sprintf(ImagePath+"/%s", id)).Receive(nil, apiErr)
	})
}

func (s *ImageService) GetByID(id string) (*Image, *http.Response, error) {
	img := new(Image)
	resp, err := trapAPIError(func(apiErr *APIError) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(ImagePath+"/%s", id)).Receive(img, apiErr)
	})
	return img, resp, err
}

func (s *ImageService) CompareState(id string, state string) (bool, error) {
	img, _, err := s.GetByID(id)
	if err != nil {
		return false, err
	}
	return (img.State == state), nil
}
