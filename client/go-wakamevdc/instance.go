package wakamevdc

import (
  "fmt"
  "net/http"
  "encoding/json"
  "bytes"
)

const InstancePath = "instances"

type Instance struct {
  ID          string `json:"id"`
  AccountID   string `json:"account_id"`
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
  QuotaWeight float32 `json:"quota_weight"`
  CreatedAt   string `json:"created_at"`
  UpdatedAt   string `json:"created_at"`
  TerminatedAt string `json:"terminated_at"`
  BootVolumeID string `json:"boot_volume_id"`
  Volumes   []struct {
    ID  string `json:"vol_id"`
    State string `json:"state"`
  } `json:"volume"`
  VIFs        []struct {
    ID               string `json:"vif_id"`
    NetworkID        string `json:"network_id"`
    SecurityGroupIDs []string `json:"security_groups"`
    IPv4 struct {
      Address string `json:"address"`
      NATAddress string `json:"nat_address"`
    } `json:"ipv4"`
  } `json:"vif"`
}

type InstanceService struct {
  client *Client
}

type InstanceCreateVIFParams struct {
  NetworkID string  `json:"network"`
  SecurityGroupIDs []string `json:"security_groups,omitempty"`
  IPv4Address string `json:"ipv4_addr,omitempty"`
  NATNetworkID string `json:"nat_network,omitempty"`
  NATIPv4Address string `json:"nat_ipv4_addr,omitempty"`
}

type InstanceCreateVolumeParams struct {
  BackupObjectID string `url:"backup_object_id,omitempty"`
  Size  int `url:"size,omitempty"`
  VolumeType string `url:"volume_type,omitempty"`
  DisplayName  string `url:"display_name,omitempty"`
  Description  string `url:"description,omitempty"`
}

type InstanceCreateParams struct {
  CPUCores     int    `url:"cpu_cores"`
  MemorySize   int    `url:"memory_size"`
  Hypervisor   string `url:"hypervisor"`
  ImageID      string `url:"image_id"`
  ServiceType  string `url:"service_type,omitempty"`
  HostNodeID   string `url:"host_node_id,omitempty"`
  SshKeyID     string `url:"ssh_key_id,omitempty"`
  Hostname     string `url:"hostname,omitempty"`
  HAEnabled    int    `url:"ha_enabled,omitempty"`
	DisplayName  string `url:"display_name,omitempty"`
  Description  string `url:"description,omitempty"`
  VIFsJSON     string `url:"vifs,omitempty"`
  VIFs         map[string]InstanceCreateVIFParams
  Volumes      []InstanceCreateVolumeParams `url:volumes,omitempty`
}

func (s *InstanceService) Create(req *InstanceCreateParams) (*Instance, *http.Response, error) {
  if req.VIFs != nil {
    buf := &bytes.Buffer{}
    err := json.NewEncoder(buf).Encode(req.VIFs)
    if err != nil {
      return nil, nil, err
    }
    req.VIFsJSON = buf.String()
  }
  inst := new(Instance)

  api_err := &APIError{}
  resp, err := s.client.Sling().Post(InstancePath).BodyForm(req).Receive(inst, api_err)
  if code := resp.StatusCode; 400 <= code {
    err = fmt.Errorf("HTTP Error %d, %s", code, api_err.Error())
  }
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
