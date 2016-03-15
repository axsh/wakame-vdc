package wakamevdc

import (
	"fmt"
	"net/http"
)

const NetworkPath = "networks"

type Network struct {
	ID                 string   `json:"id"`
	AccountID          string   `json:"account_id"`
	IPv4Network        string   `json:"ipv4_network"`
	IPv4GW             string   `json:"ipv4_gw"`
	Prefix             int      `json:"prefix"`
	NATNetworkID       string   `json:"nat_network_id"`
	Metric             int      `json:"metric"`
	IPAssignment       string   `json:"ip_assignment"`
	Editable           bool     `json:"editable"`
	DomainName         string   `json:"domain_name"`
	DNSServer          string   `json:"dns_server"`
	DHCPServer         string   `json:"dhcp_server"`
	MetadataServer     string   `json:"metadata_server"`
	MetadataServerPort int      `json:"metadata_server_port"`
	NetworkMode        string   `json:"network_mode"`
	NetworkServices    []string `json:"network_services"`
	DCNetwork          struct {
		ID                   string   `json:"id"`
		Name                 string   `json:"name"`
		Description          string   `json:"description"`
		VLANLeaseID          string   `json:"vlan_lease_id"`
		OfferringNetworkMode []string `json:"offering_network_modes"`
		AllowNewNetworks     bool     `json:"allow_new_networks"`
		CreatedAt            string   `json:"created_at"`
		UpdatedAt            string   `json:"updated_at"`
	} `json:"dc_network"`
	ServiceType string `json:"service_type"`
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
	AccountID    string `url:"account_id,omitempty"`
	IPv4Network  string `url:"network"`
	IPv4GW       string `url:"gw,omitempty"`
	Prefix       int    `url:"prefix"`
	DCNetworkID  string `url:"dc_network"`
	NetworkMode  string `url:"network_mode,omitempty"`
	DomainName   string `url:"domain_name,omitempty"`
	IPAssignment string `url:"ip_assignment,omitempty"`
	Editable     bool   `url:"editable,omitempty"`
	Metric       int    `url:"metric,omitempty"`
	ServiceType  string `url:"service_type,omitempty"`
	Description  string `url:"description,omitempty"`
	DisplayName  string `url:"display_name,omitempty"`
	// TODO: service_dhcp, service_dns, service_gateway
}

type NetworkUpdateParams struct {
	DisplayName string `url:"display_name,omitempty"`
}

func (s *NetworkService) Create(req *NetworkCreateParams) (*Network, *http.Response, error) {
	nw := new(Network)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Post(NetworkPath).BodyForm(req).Receive(nw, errResp)
	})

	return nw, resp, err
}

func (s *NetworkService) Update(id string, req *NetworkUpdateParams) (*http.Response, error) {
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(NetworkPath+"/%s", id)).BodyForm(req).Receive(nil, errResp)
	})
	return resp, err
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

func (s *NetworkService) DHCPRangeList(id string) ([][]string, *http.Response, error) {
	var drl [][]string

	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(NetworkPath+"/%s/dhcp_ranges", id)).Receive(&drl, errResp)
	})

	return drl, resp, err
}

type DHCPRangeCreateParams struct {
	RangeBegin string `url:"range_begin"`
	RangeEnd   string `url:"range_end"`
}

func (s *NetworkService) DHCPRangeCreate(id string, req *DHCPRangeCreateParams) (*http.Response, error) {
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(NetworkPath+"/%s/dhcp_ranges/add", id)).BodyForm(req).Receive(nil, errResp)
	})

	return resp, err
}

type DHCPRangeDeleteParams struct {
	RangeBegin string `url:"range_begin"`
	RangeEnd   string `url:"range_end"`
}

func (s *NetworkService) DHCPRangeDelete(id string, req *DHCPRangeDeleteParams) (*http.Response, error) {
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(NetworkPath+"/%s/dhcp_ranges/remove", id)).BodyForm(req).Receive(nil, errResp)
	})

	return resp, err
}
