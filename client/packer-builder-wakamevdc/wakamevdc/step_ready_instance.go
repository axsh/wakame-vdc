package wakamevdc

import (
	"fmt"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepReadyInstance struct{}

func (s *stepReadyInstance) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*goclient.Client)
	ui := state.Get("ui").(packer.Ui)
	c := state.Get("config").(Config)
	instID := state.Get("instance_id").(string)

	ui.Say("Waiting for instance to become running......")

	err := waitForResourceState("running", instID, client.Instance, c.StateTimeout)
	if err != nil {
		err := fmt.Errorf("Error waiting for instance to become running: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	inst, _, err := client.Instance.GetByID(instID)
	if err != nil {
		err := fmt.Errorf("Error retrieving instance: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}

	state.Put("ip_address", inst.VIFs[0].IPv4.Address)
	return multistep.ActionContinue
}

func (s *stepReadyInstance) Cleanup(state multistep.StateBag) {
	return
}
