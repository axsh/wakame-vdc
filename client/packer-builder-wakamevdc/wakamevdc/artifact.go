package wakamevdc

import (
	"fmt"
	"log"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
)

type Artifact struct {
	ImageId string

	// The client for making API calls
	client *goclient.Client
}

func (*Artifact) BuilderId() string {
	return BuilderId
}

func (*Artifact) Files() []string {
	return nil
}

func (a *Artifact) Id() string {
	return a.ImageId
}

func (a *Artifact) String() string {
	return fmt.Sprintf("A machine image was created: '%s'", a.ImageId)
}

func (a *Artifact) State(name string) interface{} {
	return nil
}

func (a *Artifact) Destroy() error {
	log.Printf("Destroying image: %s", a.ImageId)
	_, err := a.client.Images.Delete(a.ImageId)
	return err
}
