package wakamevdc

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
)

const InstancePath = "instances"

type Instance struct {
	ID          string `json:"id"`
	AccountID   string `json:"account_id"`
	DisplayName string `json:"display_name"`
	ServiceType string `json:"service_type"`
	CPUCores    int    `json:"cpu_cores"`
	MemorySize  int    `json:"memory_size"`
	State       string `json:"state"`
	Status      string `json:"status"`
	Arch        string `json:"arch"`
	HostNodeID  string `json:"host_node"`
	Hypervisor  string `json:hypervisor`
	SshKey      struct {
		ID          string `json:"uuid"`
		DisplayName string `json:"display_name"`
	} `json:"ssh_key_pair"`
	Hostname     string  `json:"hostname"`
	HAEnabled    int     `json:"ha_enabled"`
	QuotaWeight  float32 `json:"quota_weight"`
	CreatedAt    string  `json:"created_at"`
	UpdatedAt    string  `json:"created_at"`
	TerminatedAt string  `json:"terminated_at"`
	BootVolumeID string  `json:"boot_volume_id"`
	Volumes      []struct {
		ID    string `json:"vol_id"`
		State string `json:"state"`
	} `json:"volume"`
	VIFs []struct {
		ID               string   `json:"vif_id"`
		NetworkID        string   `json:"network_id"`
		SecurityGroupIDs []string `json:"security_groups"`
		IPv4             struct {
			Address    string `json:"address"`
			NATAddress string `json:"nat_address"`
		} `json:"ipv4"`
	} `json:"vif"`
}

func (i *Instance) SshKeyID() string {
	return i.SshKey.ID
}

type InstanceService struct {
	client *Client
}

type InstanceCreateVIFParams struct {
	NetworkID        string   `json:"network"`
	SecurityGroupIDs []string `json:"security_groups,omitempty"`
	IPv4Address      string   `json:"ipv4_addr,omitempty"`
	NATNetworkID     string   `json:"nat_network,omitempty"`
	NATIPv4Address   string   `json:"nat_ipv4_addr,omitempty"`
}

type InstanceCreateVolumeParams struct {
	BackupObjectID string `url:"backup_object_id,omitempty"`
	Size           int    `url:"size,omitempty"`
	VolumeType     string `url:"volume_type,omitempty"`
	DisplayName    string `url:"display_name,omitempty"`
	Description    string `url:"description,omitempty"`
}

type InstanceCreateParams struct {
	CPUCores    int    `url:"cpu_cores"`
	MemorySize  int    `url:"memory_size"`
	Hypervisor  string `url:"hypervisor"`
	ImageID     string `url:"image_id"`
	ServiceType string `url:"service_type,omitempty"`
	HostNodeID  string `url:"host_node_id,omitempty"`
	SshKeyID    string `url:"ssh_key_id,omitempty"`
	Hostname    string `url:"hostname,omitempty"`
	HAEnabled   int    `url:"ha_enabled,omitempty"`
	DisplayName string `url:"display_name,omitempty"`
	UserData    string `url:"user_data,omitempty"`
	VIFsJSON    string `url:"vifs,omitempty"`
	VIFs        map[string]InstanceCreateVIFParams
	Volumes     []InstanceCreateVolumeParams `url:"volumes,omitempty"`
}

type InstanceUpdateParams struct {
	DisplayName string `url:"display_name,omitempty"`
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
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Post(InstancePath).BodyForm(req).Receive(inst, errResp)
	})

	return inst, resp, err
}

func (s *InstanceService) Update(id string, req *InstanceUpdateParams) (*http.Response, error) {
	return trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(InstancePath+"/%s", id)).BodyForm(req).Receive(nil, errResp)
	})
}

func (s *InstanceService) Delete(id string) (*http.Response, error) {
	return trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Delete(fmt.Sprintf(InstancePath+"/%s", id)).Receive(nil, errResp)
	})
}

func (s *InstanceService) GetByID(id string) (*Instance, *http.Response, error) {
	inst := new(Instance)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(fmt.Sprintf(InstancePath+"/%s", id)).Receive(inst, errResp)
	})
	return inst, resp, err
}

func (s *InstanceService) PowerOff(id string) (*http.Response, error) {
	return trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(InstancePath+"/%s/poweroff", id)).Receive(nil, errResp)
	})
}

func (s *InstanceService) PowerOn(id string) (*http.Response, error) {
	return trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(InstancePath+"/%s/poweron", id)).Receive(nil, errResp)
	})
}

type InstanceBackupParams struct {
	All             bool   `url:"all,omitempty"`
	DisplayName     string `url:"display_name,omitempty"`
	Description     string `url:"description,omitempty"`
	IsPublic        bool   `url:"is_public,omitempty"`
	IsCacheable     bool   `url:"is_cacheable,omitempty"`
	BackupStorageID string `url:"backup_storage_id,omitempty"`
}

type InstanceBackup struct {
	ImageID        string `json:"image_id"`
	BackupObjectID string `json:"backup_object_id"`
}

func (s *InstanceService) Backup(id string, params *InstanceBackupParams) (string, *http.Response, error) {
	backup_resp := new(InstanceBackup)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Put(fmt.Sprintf(InstancePath+"/%s/backup", id)).BodyForm(params).Receive(backup_resp, errResp)
	})
	return backup_resp.ImageID, resp, err
}

func (s *InstanceService) CompareState(id string, state string) (bool, error) {
	inst, _, err := s.GetByID(id)
	if err != nil {
		return false, err
	}
	return (inst.State == state), nil
}

type InstancesList struct {
	Total   int        `json:"total"`
	Start   int        `json:"start"`
	Limit   int        `json:"limit"`
	Results []Instance `json:"results"`
}

func (s *InstanceService) List(req *ListRequestParams) (*InstancesList, *http.Response, error) {
	instList := make([]InstancesList, 1)
	resp, err := trapAPIError(func(errResp *ErrorResponse) (*http.Response, error) {
		return s.client.Sling().Get(InstancePath).QueryStruct(req).Receive(&instList, errResp)
	})

	if err == nil && len(instList) > 0 {
		return &instList[0], resp, err
	}
	// Return empty list object.
	return &InstancesList{}, resp, err
}
