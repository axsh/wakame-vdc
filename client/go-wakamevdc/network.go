package wakamevdc

import (
	"fmt"
	"net/http"
)

const NetworkPath = "networks"

type Network struct {
	ID          string `json:"id"`
	DisplayName string `json:"display_name"`
	Description string `json:"description"`
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
	DeletedAt   string `json:"deleted_at"`
}

type NetworkService struct {
	client *Client
}

type NetworkCreateParams struct {
	ServiceType string `url:"service_type,omitempty"`
	Description string `url:"description,omitempty"`
	DisplayName string `url:"display_name,omitempty"`
	Rules       string `url:"rule"`
}

func (s *NetworkService) Create(req *NetworkCreateParams) (*Network, *http.Response, error) {
	nw := new(Network)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Post(NetworkPath).BodyForm(req).Receive(nw, errResp)
	})

	return nw, resp, err
}

func (s *NetworkService) Delete(id string) (*http.Response, error) {
	return trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Delete(fmt.Sprintf(NetworkPath+"/%s", id)).Receive(nil, errResp)
	})
}

func (s *NetworkService) GetByID(id string) (*Network, *http.Response, error) {
	nw := new(Network)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(NetworkPath+"/%s", id)).Receive(nw, errResp)
	})

	return nw, resp, err
}

type NetworksList struct {
	Total   int       `json:"total"`
	Start   int       `json:"start"`
	Limit   int       `json:"limit"`
	Results []Network `json:"results"`
}

func (s *NetworkService) List(req *ListRequestParams) (*NetworksList, *http.Response, error) {
	nwList := make([]NetworksList, 1)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(NetworkPath).QueryStruct(req).Receive(&nwList, errResp)
	})

	if err == nil && len(nwList) > 0 {
		return &nwList[0], resp, err
	}
	// Return empty list object.
	return &NetworksList{}, resp, err
}
