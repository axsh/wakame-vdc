package wakamevdc

import (
	"fmt"
	"net/http"
)

const NetworkVifPath = "network_vifs"

type NetworkVif struct {
	ID               string   `json:"id"`
	IPv4Address      string   `json:"ipv4_address"`
	NatIPv4Address   string   `json:"nat_ipv4_address"`
	NetworkID        string   `json:"network_id"`
	InstanceID       string   `json:"instance_id"`
	SecurityGroupIDs []string `json:"security_groups"`
	MacAddr          string   `json:"mac_addr"`
	//TODO: Finish NetworkMonitors
	//NetworkMonitors  []struct {} `json:"network_monitors"`
	NetworkVifIpLease struct {
		IPv4      string `json:"ipv4"`
		NetworkID string `json:"network_id"`
		IPHandle  struct {
			ID          string `json:"id"`
			DisplayName string `json:"display_name"`
		} `json:"ip_handle"`
	} `json:"ip_leases"`
}

type NetworkVifService struct {
	client *Client
}

type NetworkVifsList struct {
	Total   int          `json:"total"`
	Start   int          `json:"start"`
	Limit   int          `json:"limit"`
	Results []NetworkVif `json:"results"`
}

func (s *NetworkVifService) List(req *ListRequestParams) (*NetworkVifsList, *http.Response, error) {
	nwVifList := make([]NetworkVifsList, 1)

	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(NetworkVifPath).QueryStruct(req).Receive(&nwVifList, errResp)
	})

	if err != nil {
		return &NetworkVifsList{}, resp, err
	}

	return &nwVifList[0], resp, nil
}

func (s *NetworkVifService) GetByID(id string) (*NetworkVif, *http.Response, error) {
	nwVif := new(NetworkVif)

	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(NetworkVifPath+"/%s", id)).Receive(nwVif, errResp)
	})

	return nwVif, resp, err
}

func (s *NetworkVifService) AddSecurityGroup(id string, securityGroupID string) (*NetworkVif, *http.Response, error) {
	nwVif := new(NetworkVif)

	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(NetworkVifPath+"/%s/add_security_group", id)).Receive(nwVif, errResp)
	})

	return nwVif, resp, err
}

func (s *NetworkVifService) RemoveSecurityGroup(id string, securityGroupID string) (*NetworkVif, *http.Response, error) {
	nwVif := new(NetworkVif)

	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(NetworkVifPath+"/%s/remove_security_group", id)).Receive(nwVif, errResp)
	})

	return nwVif, resp, err
}
