package wakamevdc

import (
	"fmt"
	"net/http"
)

const DCNetworkPath = "dc_networks"

type DCNetwork struct {
	ID                    string   `json:"id"`
	Name                  string   `json:"name"`
	OfferringNetworkModes []string `json:"offering_network_modes"`
	AllowNewNetwork       bool     `json:"allow_new_networks"`
	Description           string   `json:"description"`
	CreatedAt             string   `json:"created_at"`
	UpdatedAt             string   `json:"updated_at"`
}

type DCNetworkService struct {
	client *Client
}

type DCNetworkCreateParams struct {
	Name        string `url:"name"`
	Description string `url:"description,omitempty"`
}

func (s *DCNetworkService) Create(req *DCNetworkCreateParams) (*DCNetwork, *http.Response, error) {
	nw := new(DCNetwork)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Post(DCNetworkPath).BodyForm(req).Receive(nw, errResp)
	})

	return nw, resp, err
}

func (s *DCNetworkService) Delete(id string) (*http.Response, error) {
	return trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Delete(fmt.Sprintf(DCNetworkPath+"/%s", id)).Receive(nil, errResp)
	})
}

func (s *DCNetworkService) GetByID(id string) (*DCNetwork, *http.Response, error) {
	nw := new(DCNetwork)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(DCNetworkPath+"/%s", id)).Receive(nw, errResp)
	})

	return nw, resp, err
}

type DCNetworksList struct {
	Total   int         `json:"total"`
	Start   int         `json:"start"`
	Limit   int         `json:"limit"`
	Results []DCNetwork `json:"results"`
}

type DCNetworkListRequestParams struct {
	Name string `url:"name,omitempty"`
}

func (s *DCNetworkService) List(req *ListRequestParams, name string) (*DCNetworksList, *http.Response, error) {
	dcnList := make([]DCNetworksList, 1)
	dcnReq := new(DCNetworkListRequestParams)
	if name != "" {
		dcnReq.Name = name
	}
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(DCNetworkPath).QueryStruct(req).QueryStruct(dcnReq).Receive(&dcnList, errResp)
	})

	if err == nil && len(dcnList) == 1 {
		return &dcnList[0], resp, err
	}
	// Return empty list object.
	return &DCNetworksList{}, resp, err
}
