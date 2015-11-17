package wakamevdc

import (
	//"fmt"

	//"github.com/digitalocean/godo"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepPowerOff struct {}

func (s *stepPowerOff) Run(state multistep.StateBag) multistep.StepAction {
  state.Get("ui").(packer.Ui).Say("Power off instance...")

  return multistep.ActionContinue
}

func (s *stepPowerOff) Cleanup(state multistep.StateBag) {
  return
}
