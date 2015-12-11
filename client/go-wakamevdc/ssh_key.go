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
	PrivateKey  string              `json:"private_key"`
	Labels      []map[string]string `json:"labels"`
}

type SshKeyService struct {
	client *Client
}

type SshKeyCreateParams struct {
	DisplayName string `url:"display_name,omitempty"`
	Description string `url:"description,omitempty"`
	ServiceType string `url:"service_type,omitempty"`
	PublicKey   string `url:"public_key"`
}

type SshKeyUpdateParams struct {
	DisplayName string `url:"display_name,omitempty"`
	Description string `url:"description,omitempty"`
	ServiceType string `url:"service_type,omitempty"`
}

func (s *SshKeyService) Create(req *SshKeyCreateParams) (*SshKey, *http.Response, error) {
	ssh_key := new(SshKey)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Post(SshKeyPath).BodyForm(req).Receive(ssh_key, errResp)
	})
	return ssh_key, resp, err
}

func (s *SshKeyService) Update(id string, req *SshKeyUpdateParams) (*http.Response, error) {
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(SshKeyPath+"/%s", id)).BodyForm(req).Receive(nil, errResp)
	})
	return resp, err
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

type SshKeysList struct {
	Total   int      `json:"total"`
	Start   int      `json:"start"`
	Limit   int      `json:"limit"`
	Results []SshKey `json:"results"`
}

func (s *SshKeyService) List(req *ListRequestParams) (*SshKeysList, *http.Response, error) {
	sshkList := make([]SshKeysList, 1)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(SshKeyPath).QueryStruct(req).Receive(&sshkList, errResp)
	})

	if err == nil && len(sshkList) > 0 {
		return &sshkList[0], resp, err
	}
	// Return empty list object.
	return &SshKeysList{}, resp, err
}
