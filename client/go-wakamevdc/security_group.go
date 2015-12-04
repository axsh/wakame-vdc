package wakamevdc

import (
	"fmt"
	"net/http"
)

const SecurityGroupPath = "security_groups"

type SecurityGroup struct {
	ID          string `json:"id"`
	CreatedAt   string `json:"created_at"`
	DisplayName string `json:"display_name"`
	Description string `json:"description"`
}

type SecurityGroupService struct {
	client *Client
}

type SecurityGroupCreateParams struct {
	DisplayName string `url:"display_name,omitempty"`
	Rule        string `url:"rules"`
}

func (s *SecurityGroupService) Create(req *SecurityGroupCreateParams) (*SecurityGroup, *http.Response, error) {
	secg := new(SecurityGroup)
	resp, err := trapAPIError(func(apiErr *APIError) (*http.Response, error) {
		return s.client.Sling().Post(SecurityGroupPath).BodyForm(req).Receive(secg, apiErr)
	})

	return secg, resp, err
}

func (s *SecurityGroupService) Delete(id string) (*http.Response, error) {
	return trapAPIError(func(apiErr *APIError) (*http.Response, error) {
		return s.client.Sling().Delete(fmt.Sprintf(SecurityGroupPath+"/%s", id)).Receive(nil, apiErr)
	})
}

func (s *SecurityGroupService) GetByID(id string) (*SecurityGroup, *http.Response, error) {
	secg := new(SecurityGroup)
	resp, err := trapAPIError(func(apiErr *APIError) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(SecurityGroupPath+"/%s", id)).Receive(secg, apiErr)
	})

	return secg, resp, err
}
