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
	resp, err := s.client.Sling().Post(SecurityGroupPath).BodyForm(req).ReceiveSuccess(secg)
	return secg, resp, err
}

func (s *SecurityGroupService) Delete(id string) (*http.Response, error) {
	resp, err := s.client.Sling().Delete(fmt.Sprintf(SecurityGroupPath+"/%s", id)).Receive(nil, nil)
	return resp, err
}

func (s *SecurityGroupService) GetByID(id string) (*SecurityGroup, *http.Response, error) {
	secg := new(SecurityGroup)
	resp, err := s.client.Sling().Get(fmt.Sprintf(SecurityGroupPath+"/%s", id)).ReceiveSuccess(secg)
	return secg, resp, err
}
