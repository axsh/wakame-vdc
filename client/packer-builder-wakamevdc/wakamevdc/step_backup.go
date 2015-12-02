package wakamevdc

import (
	"fmt"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepBackup struct{}

func (s *stepBackup) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*goclient.Client)
	ui := state.Get("ui").(packer.Ui)
	conf := state.Get("config").(Config)
	instID := state.Get("instance_id").(string)

	ui.Say("Take instance backup...")
	imageID, _, err := client.Instance.Backup(instID, &goclient.InstanceBackupParams{
		All: false,
	})
	if err != nil {
		err := fmt.Errorf("Error turning instance off: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	ui.Say("New image: " + imageID)

	err = waitForResourceState("available", imageID, client.Image, conf.StateTimeout)
	if err != nil {
		err := fmt.Errorf("Error waiting for image to become available: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	ui.Say("Image created...")

	state.Put("image_id", imageID)
	return multistep.ActionContinue
}

func (s *stepBackup) Cleanup(state multistep.StateBag) {
	return
}
