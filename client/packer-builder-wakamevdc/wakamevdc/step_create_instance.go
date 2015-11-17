package wakamevdc

import (
	//"fmt"

	//"github.com/digitalocean/godo"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepCreateInstance struct {
	InstanceId string
}

func (s *stepCreateInstance) Run(state multistep.StateBag) multistep.StepAction {
  state.Get("ui").(packer.Ui).Say("Creating instance...")

  state.Put("instance_id", "i-xxxx")
  return multistep.ActionContinue
}

func (s *stepCreateInstance) Cleanup(state multistep.StateBag) {
  return
}
