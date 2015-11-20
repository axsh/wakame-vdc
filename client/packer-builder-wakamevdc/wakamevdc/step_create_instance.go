package wakamevdc

import (
	"fmt"

	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
	wakamevdc "github.com/axsh/wakame-vdc/client/go-wakamevdc"
)

type stepCreateInstance struct {
	InstanceID string
}

func (s *stepCreateInstance) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*wakamevdc.Client)
	ui := state.Get("ui").(packer.Ui)

  ui.Say("Creating instance...")
	inst, resp, err := client.Instance.Create(&wakamevdc.InstanceCreateParams{
    Hypervisor: "openvz",
    CPUCores: 1,
    MemorySize: 128,
    ImageID: "wmi-centos1d64",
  })
	if err == nil &&  resp.StatusCode != 200 {
		err = fmt.Errorf(resp.Status)
	}
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
