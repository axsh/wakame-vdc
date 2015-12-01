package wakamevdc

import (
	"fmt"
	"log"
  "time"
	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
)

func waitForResourceState(
	desiredState string, resource_id string,
	wait_for_tgt goclient.StateCompare, timeout time.Duration) error {
	done := make(chan struct{})
	defer close(done)

	result := make(chan error, 1)
	go func() {
		attempts := 0
		for {
			attempts += 1

			log.Printf("Checking %s status... (attempt: %d)", resource_id, attempts)
			state_match, err := wait_for_tgt.CompareState(resource_id, desiredState)
			if err != nil {
				result <- err
				return
			}

			if state_match == true {
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
