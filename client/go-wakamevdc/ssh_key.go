package wakamevdc

import (
	"fmt"
	"net/http"
)

const SshKeyPath = "ssh_key_pairs"

type SshKey struct {
	ID          string              `json:"id"`
	AccountId   string              `json:"account_id"`
	Fingerprint string              `json:"finger_print"`
	PublicKey   string              `json:"public_key"`
	Description string              `json:"description"`
	CreatedAt   string              `json:"created_at"`
	UpdatedAt   string              `json:"updated_at"`
	DeletedAt   string              `json:"deleted_at"`
	ServiceType string              `json:"service_type"`
	DisplayName string              `json:"display_name"`
	Labels      []map[string]string `json:"labels"`
}

type SshKeyService struct {
	client *Client
}

type SshKeyCreateParams struct {
	DisplayName string `url:"display_name,omitempty"`
	Description string `url:"description"`
	PublicKey   string `url:"public_key"`
}

func (s *SshKeyService) Create(req *SshKeyCreateParams) (*SshKey, *http.Response, error) {
	ssh_key := new(SshKey)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Post(SshKeyPath).BodyForm(req).Receive(ssh_key, errResp)
	})
	return ssh_key, resp, err
}

func (s *SshKeyService) Delete(id string) (*http.Response, error) {
	return trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Delete(fmt.Sprintf(SshKeyPath+"/%s", id)).Receive(nil, errResp)
	})
}

func (s *SshKeyService) GetByID(id string) (*SshKey, *http.Response, error) {
	ssh_key := new(SshKey)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(SshKeyPath+"/%s", id)).Receive(ssh_key, errResp)
	})
	return ssh_key, resp, err
}
