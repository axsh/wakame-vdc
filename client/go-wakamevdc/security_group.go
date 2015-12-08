package wakamevdc

import (
	"fmt"
	"net/http"
)

const SecurityGroupPath = "security_groups"

type SecurityGroup struct {
	ID          string `json:"id"`
	AccountID   string `json:"account_id"`
	ServiceType string `json:"service_type"`
	CreatedAt   string `json:"created_at"`
	DisplayName string `json:"display_name"`
	Description string `json:"description"`
	Rules       string `json:"rule"`
	UpdatedAt   string `json:"updated_at"`
	DeletedAt   string `json:"deleted_at"`
}

type SecurityGroupService struct {
	client *Client
}

type SecurityGroupCreateParams struct {
	ServiceType string `url:"service_type,omitempty"`
	Description string `url:"description,omitempty"`
	DisplayName string `url:"display_name,omitempty"`
	Rules       string `url:"rule"`
}

func (s *SecurityGroupService) Create(req *SecurityGroupCreateParams) (*SecurityGroup, *http.Response, error) {
	secg := new(SecurityGroup)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Post(SecurityGroupPath).BodyForm(req).Receive(secg, errResp)
	})

	return secg, resp, err
}

func (s *SecurityGroupService) Delete(id string) (*http.Response, error) {
	return trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Delete(fmt.Sprintf(SecurityGroupPath+"/%s", id)).Receive(nil, errResp)
	})
}

func (s *SecurityGroupService) GetByID(id string) (*SecurityGroup, *http.Response, error) {
	secg := new(SecurityGroup)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(SecurityGroupPath+"/%s", id)).Receive(secg, errResp)
	})

	return secg, resp, err
}
