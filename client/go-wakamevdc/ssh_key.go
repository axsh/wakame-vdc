package wakamevdc

import (
	"fmt"
	"net/http"
)

const SshKeyPath = "ssh_key_pairs"

type SshKey struct {
	ID          string `json:"id"`
	PublicKey   string `json:"public_key"`
	Fingerprint string `json:"finger_print"`
	CreatedAt   string `json:"created_at"`
	Description string `json:"description"`
	PrivateKey  string `json:"private_key"`
}

type SshKeyService struct {
	client *Client
}

type SshKeyCreateParams struct {
	DisplayName string `url:"display_name,omitempty"`
	PublicKey   string `url:"public_key"`
}

func (s *SshKeyService) Create(req *SshKeyCreateParams) (*SshKey, *http.Response, error) {
	ssh_key := new(SshKey)
	resp, err := trapAPIError(func(apiErr *APIError) (*http.Response, error) {
		return s.client.Sling().Post(SshKeyPath).BodyForm(req).Receive(ssh_key, apiErr)
	})
	return ssh_key, resp, err
}

func (s *SshKeyService) Delete(id string) (*http.Response, error) {
	return trapAPIError(func(apiErr *APIError) (*http.Response, error) {
		return s.client.Sling().Delete(fmt.Sprintf(SshKeyPath+"/%s", id)).Receive(nil, apiErr)
	})
}

func (s *SshKeyService) GetByID(id string) (*SshKey, *http.Response, error) {
	ssh_key := new(SshKey)
	resp, err := trapAPIError(func(apiErr *APIError) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(SshKeyPath+"/%s", id)).Receive(ssh_key, apiErr)
	})
	return ssh_key, resp, err
}
