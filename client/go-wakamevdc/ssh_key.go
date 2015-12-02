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
	sshKey := new(SshKey)
	resp, err := s.client.Sling().Post(SshKeyPath).BodyForm(req).ReceiveSuccess(sshKey)
	return sshKey, resp, err
}

func (s *SshKeyService) Delete(id string) (*http.Response, error) {
	resp, err := s.client.Sling().Delete(fmt.Sprintf(SshKeyPath+"/%s", id)).Receive(nil, nil)
	return resp, err
}

func (s *SshKeyService) GetByID(id string) (*SshKey, *http.Response, error) {
	sshKey := new(SshKey)
	resp, err := s.client.Sling().Get(fmt.Sprintf(SshKeyPath+"/%s", id)).ReceiveSuccess(sshKey)
	return sshKey, resp, err
}
