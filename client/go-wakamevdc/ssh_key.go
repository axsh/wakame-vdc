package wakamevdc

import (
  "net/http"
)

type SshKeyAPI interface {
  Create(*SshKeyCreateRequest) (*SshKey, *http.Response, error)
}

const SshKeyPath = "ssh_key_pairs"

type SshKey struct {
  ID          string `json:"uuid"`
  PublicKey   string `json:"public_key"`
  Fingerprint string `json:"fingerprint"`
  CreatedAt   string `json:"created_at"`
}

type SshKeyService struct {
  client *Client
}

type SshKeyCreateRequest struct {
	DisplayName  string `url:"display_name,omitempty"`
	PublicKey    string `url:"public_key"`
}

// Create a key using a KeyCreateRequest
func (s *SshKeyService) Create(req *SshKeyCreateRequest) (*SshKey, *http.Response, error) {
  ssh_key := new(SshKey)
  resp, err := s.client.Sling().Post(SshKeyPath).BodyForm(req).ReceiveSuccess(ssh_key)
  return ssh_key, resp, err
}
