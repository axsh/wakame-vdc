package wakamevdc

import (
	"fmt"
	"log"
	"net/url"

	goclient "github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/mitchellh/multistep"
	"github.com/mitchellh/packer/common"
	"github.com/mitchellh/packer/helper/communicator"
	"github.com/mitchellh/packer/packer"
	"golang.org/x/crypto/ssh"
)

// The unique id for the builder
const BuilderId = "axsh.wakamevdc"

type Builder struct {
	config Config
	runner multistep.Runner
}

func (b *Builder) Prepare(raws ...interface{}) ([]string, error) {
	c, warnings, errs := NewConfig(raws...)
	if errs != nil {
		return warnings, errs
	}
	b.config = *c

	return nil, nil
}

func (b *Builder) Run(ui packer.Ui, hook packer.Hook, cache packer.Cache) (packer.Artifact, error) {
	baseURL, err := url.Parse(b.config.APIEndpoint + "/")
	if err != nil {
		return nil, err
	}

	client := goclient.NewClient(baseURL, nil)

	// Set up the state
	state := new(multistep.BasicStateBag)
	state.Put("config", b.config)
	state.Put("client", client)
	state.Put("hook", hook)
	state.Put("ui", ui)

	// Build the steps
	steps := []multistep.Step{
		&stepSetup{},
		new(stepCreateInstance),
		new(stepReadyInstance),
		&communicator.StepConnect{
			Config:    &b.config.Comm,
			Host:      commHost,
			SSHConfig: sshConfig,
		},
		new(common.StepProvision),
		new(stepPowerOff),
		new(stepBackup),
		new(stepTerminate),
	}

	// Run the steps
	if b.config.PackerDebug {
		b.runner = &multistep.DebugRunner{
			Steps:   steps,
			PauseFn: common.MultistepDebugFn(ui),
		}
	} else {
		b.runner = &multistep.BasicRunner{Steps: steps}
	}

	b.runner.Run(state)

	_, cancelled := state.GetOk(multistep.StateCancelled)
	if cancelled {
		return nil, nil
	}
	_, halted := state.GetOk(multistep.StateHalted)
	if halted {
		if rawErr, ok := state.GetOk("error"); ok {
			return nil, rawErr.(error)
		}
		return nil, fmt.Errorf("Failed to build image by unkown reason.")
	}

	if _, ok := state.GetOk("image_id"); !ok {
		return nil, fmt.Errorf("Failed to find image_id in state. Bug?")
	}

	artifact := &Artifact{
		ImageId: state.Get("image_id").(string),
		client:  client,
	}

	return artifact, nil
}

func (b *Builder) Cancel() {
	if b.runner != nil {
		log.Println("Cancelling the step runner...")
		b.runner.Cancel()
	}
}

func commHost(state multistep.StateBag) (string, error) {
	ipAddress := state.Get("ip_address").(string)
	return ipAddress, nil
}

func sshConfig(state multistep.StateBag) (*ssh.ClientConfig, error) {
	config := state.Get("config").(Config)
	privateKey := state.Get("ssh_private_key").(string)

	signer, err := ssh.ParsePrivateKey([]byte(privateKey))
	if err != nil {
		return nil, fmt.Errorf("Error setting up SSH config: %s", err)
	}

	return &ssh.ClientConfig{
		User: config.Comm.SSHUsername,
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(signer),
		},
	}, nil
}

func isStepAborted(state multistep.StateBag) bool {
	_, cancelled := state.GetOk(multistep.StateCancelled)
	_, halted := state.GetOk(multistep.StateHalted)
	return cancelled || halted
}
