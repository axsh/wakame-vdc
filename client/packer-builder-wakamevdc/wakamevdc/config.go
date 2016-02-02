package wakamevdc

import (
	"errors"
	//"fmt"
	"net/url"
	"os"
	"time"

	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/common"
	"github.com/mitchellh/packer/helper/communicator"
	"github.com/mitchellh/packer/helper/config"
	"github.com/mitchellh/packer/packer"
	"github.com/mitchellh/packer/template/interpolate"
)

type Config struct {
	common.PackerConfig `mapstructure:",squash"`
	Comm                communicator.Config `mapstructure:",squash"`

	APIEndpoint string `mapstructure:"api_endpoint"`

	ImageID   string `mapstructure:"image_id"`
	AccountID string `mapstructure:"account_id"`

	Hypervisor      string `mapstructure:"hypervisor"`
	CPUCores        int    `mapstructure:"cpu_cores"`
	MemorySize      int    `mapstructure:"memory_size"`
	HostNodeID      string `mapstructure:"host_node_id"`
	VIF1NetworkID   string `mapstructure:"network_id"`
	SshKeyID        string `mapstructure:"ssh_key_id"`
	UserData        string `mapstructure:"user_data"`
	BackupStorageID string `mapstructure:"backup_storage_id"`

	StateTimeout time.Duration `mapstructure:"state_timeout"`

	ctx interpolate.Context
}

func NewConfig(raws ...interface{}) (*Config, []string, error) {
	c := new(Config)

	var md mapstructure.Metadata
	err := config.Decode(c, &config.DecodeOpts{
		Metadata:           &md,
		Interpolate:        true,
		InterpolateContext: &c.ctx,
		InterpolateFilter: &interpolate.RenderFilter{
			Exclude: []string{
				"run_command",
			},
		},
	}, raws...)
	if err != nil {
		return nil, nil, err
	}

	// Defaults
	if c.APIEndpoint == "" {
		c.APIEndpoint = os.Getenv("WAKAMEVDC_API_ENDPOINT")
	}

	if c.CPUCores == 0 {
		c.CPUCores = 1
	}

	if c.MemorySize == 0 {
		c.MemorySize = 512
	}

	if c.Comm.SSHUsername == "" {
		// Default to "root". You can override this if your
		// SourceImage has a different user account then the DO default
		c.Comm.SSHUsername = "root"
	}

	if c.StateTimeout == 0 {
		// Default to 6 minute timeouts waiting for
		// desired state. i.e waiting for droplet to become active
		c.StateTimeout = 6 * time.Minute
	}

	var errs *packer.MultiError
	if es := c.Comm.Prepare(&c.ctx); len(es) > 0 {
		errs = packer.MultiErrorAppend(errs, es...)
	}
	if c.APIEndpoint == "" {
		c.APIEndpoint = "http://localhost:9001/api/12.03/"
	} else {
		_, err := url.Parse(c.APIEndpoint)
		if err != nil {
			errs = packer.MultiErrorAppend(
				errs, errors.New("api_endpoint is invalid"))
		}
	}

	if c.ImageID == "" {
		errs = packer.MultiErrorAppend(
			errs, errors.New("image_id is required"))
	}

	if c.CPUCores < 1 {
		errs = packer.MultiErrorAppend(
			errs, errors.New("cpu_cores must have positive integer"))
	}

	if c.MemorySize < 1 {
		errs = packer.MultiErrorAppend(
			errs, errors.New("memorys_size must have positive integer"))
	}

	if c.Hypervisor == "" {
		errs = packer.MultiErrorAppend(
			errs, errors.New("hypervisor must be either of available hyperivsors: lxc, openvz, kvm"))
	}

	if c.VIF1NetworkID == "" {
		errs = packer.MultiErrorAppend(
			errs, errors.New("network_id is required"))
	}

	if errs != nil && len(errs.Errors) > 0 {
		return nil, nil, errs
	}

	return c, nil, nil
}
