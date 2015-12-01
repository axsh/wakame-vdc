package wakamevdc

import (
	"fmt"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepPowerOff struct {}

func (s *stepPowerOff) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*goclient.Client)
	ui := state.Get("ui").(packer.Ui)
	conf := state.Get("config").(Config)
	inst_id := state.Get("instance_id").(string)

	ui.Say("Power off instance...")
	_, err := client.Instance.PowerOff(inst_id)
	if err != nil {
		err := fmt.Errorf("Error turning instance off: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	err = waitForResourceState("halted", inst_id, client.Instance, conf.StateTimeout)
	if err != nil {
		err := fmt.Errorf("Error waiting for instance to become running: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	ui.Say("Instance halted...")

  return multistep.ActionContinue
}

func (s *stepPowerOff) Cleanup(state multistep.StateBag) {
  return
}
