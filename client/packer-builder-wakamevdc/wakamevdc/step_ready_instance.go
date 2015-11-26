package wakamevdc

import (
	"fmt"
	"log"
	"time"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/packer"
)

type stepReadyInstance struct {}

func (s *stepReadyInstance) Run(state multistep.StateBag) multistep.StepAction {
	client := state.Get("client").(*goclient.Client)
	ui := state.Get("ui").(packer.Ui)
	c := state.Get("config").(Config)
	inst_id := state.Get("instance_id").(string)

	ui.Say("Waiting for instance to become running......")

	err := waitForInstanceState("running", inst_id, client, c.StateTimeout)
	if err != nil {
		err := fmt.Errorf("Error waiting for instance to become running: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}
	inst, _, err := client.Instance.GetByID(inst_id)
	if err != nil {
		err := fmt.Errorf("Error retrieving instance: %s", err)
		state.Put("error", err)
		ui.Error(err.Error())
		return multistep.ActionHalt
	}

	state.Put("ip_address", inst.VIFs[0].IPv4.Address)
  return multistep.ActionContinue
}

func (s *stepReadyInstance) Cleanup(state multistep.StateBag) {
  return
}

func waitForInstanceState(
	desiredState string, instanceID string,
	client *goclient.Client, timeout time.Duration) error {
	done := make(chan struct{})
	defer close(done)

	result := make(chan error, 1)
	go func() {
		attempts := 0
		for {
			attempts += 1

			log.Printf("Checking instance status... (attempt: %d)", attempts)
			inst, _, err := client.Instance.GetByID(instanceID)
			if err != nil {
				result <- err
				return
			}

			if inst.State == desiredState {
				result <- nil
				return
			}

			// Wait 3 seconds in between
			time.Sleep(3 * time.Second)

			// Verify we shouldn't exit
			select {
			case <-done:
				// We finished, so just exit the goroutine
				return
			default:
				// Keep going
			}
		}
	}()

	log.Printf("Waiting for up to %d seconds for instance to become %s", timeout/time.Second, desiredState)
	select {
	case err := <-result:
		return err
	case <-time.After(timeout):
		err := fmt.Errorf("Timeout while waiting to for instance to become '%s'", desiredState)
		return err
	}
}
