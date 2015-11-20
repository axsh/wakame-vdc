package wakamevdc

import (
  "fmt"
  "net/http"
)

const InstancePath = "instances"

type Instance struct {
  ID          string `json:"id"`
  AccountID   string `json:"account_idd"`
  DisplayName string `json:"display_name"`
  Description string `json:"description"`
  ServiceType string `json:"service_type"`
  State       string `json:"state"`
  Status      string `json:"status"`
  Arch        string `json:"arch"`
  HostNode    string `json:"host_node"`
  SshKeyID    string `json:"ssh_key_pair"`
  Hostname    string `json:"hostname"`
  HAEnabled   int    `json:"ha_enabled"`
  CreatedAt   string `json:"created_at"`
  UpdatedAt   string `json:"created_at"`
  TerminatedAt string `json:"terminated_at"`
}

type InstanceService struct {
  client *Client
}

type InstanceCreateParams struct {
  CPUCores     int    `url:"cpu_cores"`
  MemorySize   int    `url:"memory_size"`
  Hypervisor   string `url:"hypervisor"`
  ImageID      string `url:"image_id"`
	DisplayName  string `url:"display_name,omitempty"`
}

func (s *InstanceService) Create(req *InstanceCreateParams) (*Instance, *http.Response, error) {
  inst := new(Instance)
  resp, err := s.client.Sling().Post(InstancePath).BodyForm(req).ReceiveSuccess(inst)
  return inst, resp, err
}

func (s *InstanceService) Delete(id string) (*http.Response, error) {
  resp, err := s.client.Sling().Delete(fmt.Sprintf(InstancePath + "/%s", id)).Receive(nil, nil)
  return resp, err
}

func (s *InstanceService) GetByID(id string) (*Instance, *http.Response, error) {
  inst := new(Instance)
  resp, err := s.client.Sling().Get(fmt.Sprintf(InstancePath + "/%s", id)).ReceiveSuccess(inst)
  return inst, resp, err
}
