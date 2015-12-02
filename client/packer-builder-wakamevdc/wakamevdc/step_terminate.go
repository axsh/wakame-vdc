package wakamevdc

import (
	"fmt"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepTerminate struct{}

func (s *stepTerminate) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*goclient.Client)
	ui := state.Get("ui").(packer.Ui)
	instID := state.Get("instance_id").(string)

	ui.Say("Terminate instance...")
	_, err := client.Instance.Delete(instID)
	if err != nil {
		err = fmt.Errorf("Error terminating instance: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	return multistep.ActionContinue
}

func (s *stepTerminate) Cleanup(state multistep.StateBag) {
	return
}
