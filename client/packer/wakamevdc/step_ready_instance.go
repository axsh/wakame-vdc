package wakamevdc

import (
	//"fmt"

	//"github.com/digitalocean/godo"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepReadyInstance struct {}

func (s *stepReadyInstance) Run(state multistep.StateBag) multistep.StepAction {
  state.Get("ui").(packer.Ui).Say("Waiting for instance to become active......")

	state.Put("ip_address", "0.0.0.0")
  return multistep.ActionContinue
}

func (s *stepReadyInstance) Cleanup(state multistep.StateBag) {
  return
}
