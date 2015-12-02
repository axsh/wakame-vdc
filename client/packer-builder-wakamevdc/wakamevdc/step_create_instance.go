package wakamevdc

import (
	"fmt"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepCreateInstance struct {
	InstanceID string
}

func (s *stepCreateInstance) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*goclient.Client)
	ui := state.Get("ui").(packer.Ui)
	conf := state.Get("config").(Config)

	sshKeyID := state.Get("ssh_key_id").(string)
	securityGroupIDs := []string{state.Get("security_group_id").(string)}
	ui.Say("Creating instance...")
	inst, _, err := client.Instance.Create(&goclient.InstanceCreateParams{
		Hypervisor: conf.Hypervisor,
		CPUCores:   conf.CPUCores,
		MemorySize: conf.MemorySize,
		ImageID:    conf.ImageID,
		HostNodeID: conf.HostNodeID,
		//UserData: conf.UserData,
		SshKeyID: sshKeyID,
		VIFs: map[string]goclient.InstanceCreateVIFParams{
			"eth0": {
				NetworkID:        conf.VIF1NetworkID,
				SecurityGroupIDs: securityGroupIDs,
			},
		},
	})
	if err != nil {
		err := fmt.Errorf("Error creating instance: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}

	s.InstanceID = inst.ID
	state.Put("instance_id", inst.ID)
	return multistep.ActionContinue
}

func (s *stepCreateInstance) Cleanup(state multistep.StateBag) {
	return
}
