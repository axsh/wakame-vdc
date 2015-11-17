package wakamevdc

import (
	"fmt"
	"log"

	//"github.com/digitalocean/godo"
)

type Artifact struct {
	ImageId string

	// The client for making API calls
	//client *godo.Client
}

func (*Artifact) BuilderId() string {
	return BuilderId
}

func (*Artifact) Files() []string {
	// No files with DigitalOcean
	return nil
}

func (a *Artifact) Id() string {
	return fmt.Sprintf("%s", a.ImageId)
}

func (a *Artifact) String() string {
	return fmt.Sprintf("A snapshot was created: '%s'", a.ImageId)
}

func (a *Artifact) State(name string) interface{} {
	return nil
}

func (a *Artifact) Destroy() error {
	log.Printf("Destroying image: %s", a.ImageId)
	//_, err := a.client.Images.Delete(a.snapshotId)
	//return err
  return nil
}
