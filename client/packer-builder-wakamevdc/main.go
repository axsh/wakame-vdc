package main

import (
	"github.com/axsh/wakame-vdc/client/packer-builder-wakamevdc/wakamevdc"
	"github.com/mitchellh/packer/packer/plugin"
)

func main() {
	server, err := plugin.Server()
	if err != nil {
		panic(err)
	}
	server.RegisterBuilder(new(wakamevdc.Builder))
	server.Serve()
}
