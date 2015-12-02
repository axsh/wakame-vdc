package wakamevdc

import (
	"fmt"
	"log"
	"time"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
)

func waitForResourceState(
	desiredState string, resourceID string,
	waitForTgt goclient.StateCompare, timeout time.Duration) error {
	done := make(chan struct{})
	defer close(done)

	result := make(chan error, 1)
	go func() {
		attempts := 0
		for {
			attempts += 1

			log.Printf("Checking %s status... (attempt: %d)", resourceID, attempts)
			stateMatch, err := waitForTgt.CompareState(resourceID, desiredState)
			if err != nil {
				result <- err
				return
			}

			if stateMatch == true {
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
