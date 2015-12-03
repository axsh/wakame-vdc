package wakamevdc

import (
	"fmt"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepBackup struct {
	imageID string
}

func (s *stepBackup) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*goclient.Client)
	ui := state.Get("ui").(packer.Ui)
	conf := state.Get("config").(Config)
	instID := state.Get("instance_id").(string)

	ui.Say("Taking instance backup...")
	imageID, _, err := client.Instance.Backup(instID, &goclient.InstanceBackupParams{
		All: false,
	})
	if err != nil {
		err := fmt.Errorf("Error taking instance backup: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	ui.Say("New image: " + imageID)
	state.Put("image_id", imageID)
	s.imageID = imageID

	err = waitForResourceState("available", imageID, client.Image, conf.StateTimeout)
	if err != nil {
		err := fmt.Errorf("Error waiting for image to become available: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	ui.Say("Image created...")

	return multistep.ActionContinue
}

func (s *stepBackup) Cleanup(state multistep.StateBag) {
	if s.imageID == "" || !isStepAborted(state) {
		return
	}

	ui := state.Get("ui").(packer.Ui)
	ui.Say("Deregistering the Image because cancelation or error...")
	client := state.Get("client").(*goclient.Client)
	if _, err := client.Image.Delete(s.imageID); err != nil {
		ui.Error(fmt.Sprintf("Error deregistering Image, may still be around: %s", err))
		return
	}
	return
}
