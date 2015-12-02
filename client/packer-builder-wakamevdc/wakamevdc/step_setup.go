package wakamevdc

import (
	"fmt"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepSetup struct{}

func (s *stepSetup) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*goclient.Client)
	ui := state.Get("ui").(packer.Ui)
	//conf := state.Get("config").(Config)

	ui.Say("Creating SSH Key...")
	sshKey, _, err := client.SshKey.Create(&goclient.SshKeyCreateParams{})
	if err != nil {
		err := fmt.Errorf("Error creating ssh key: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	ui.Say("New SSH Key: " + sshKey.ID)
	state.Put("ssh_key_id", sshKey.ID)
	state.Put("ssh_private_key", sshKey.PrivateKey)
	// Validate private key syntax
	_, err = sshConfig(state)
	if err != nil {
		err := fmt.Errorf("Error private key contents: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}

	ui.Say("Creating Security Group...")
	securityGroup, _, err := client.SecurityGroup.Create(&goclient.SecurityGroupCreateParams{
		Rule: "tcp:22,22,ip4:0.0.0.0",
	})
	if err != nil {
		err := fmt.Errorf("Error creating security group: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	ui.Say("New Security Group: " + securityGroup.ID)
	state.Put("security_group_id", securityGroup.ID)

	return multistep.ActionContinue
}

func (s *stepSetup) Cleanup(state multistep.StateBag) {
	return
}
