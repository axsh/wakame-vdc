package wakamevdc

import (
	"fmt"

	//"github.com/digitalocean/godo"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepCreateInstance struct {
	InstanceId string
}

func (s *stepCreateInstance) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*Client)
	ui := state.Get("ui").(packer.Ui)

  ui.Say("Creating instance...")
	resp, err := client.Request("POST", "instances", nil)
	if err == nil &&  resp.StatusCode != 200 {
		err = fmt.Errorf(resp.Status)
	}
	if err != nil {
		err := fmt.Errorf("Error creating instance: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	ui.Say(resp.Status)
  state.Put("instance_id", "i-xxxx")
  return multistep.ActionContinue
}

func (s *stepCreateInstance) Cleanup(state multistep.StateBag) {
  return
}
