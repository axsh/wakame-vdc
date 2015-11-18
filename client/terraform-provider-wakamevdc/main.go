package main

import (
	"github.com/axsh/wakame-vdc/client/terraform-provider-wakamevdc/wakamevdc"
	"github.com/hashicorp/terraform/plugin"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: wakamevdc.Provider,
	})
}
