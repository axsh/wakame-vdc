package wakamevdc

import (
	//"fmt"

	//"github.com/digitalocean/godo"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepBackup struct {}

func (s *stepBackup) Run(state multistep.StateBag) multistep.StepAction {
  state.Get("ui").(packer.Ui).Say("Take instance backup...")

  return multistep.ActionContinue
}

func (s *stepBackup) Cleanup(state multistep.StateBag) {
  return
}
