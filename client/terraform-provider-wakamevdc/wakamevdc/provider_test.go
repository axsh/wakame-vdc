package wakamevdc

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

var testVdcProviders map[string]terraform.ResourceProvider
var testVdcProvider *schema.Provider

func init() {
	testVdcProvider = Provider().(*schema.Provider)
	testVdcProviders = map[string]terraform.ResourceProvider{
		"wakamevdc": testVdcProvider,
	}
}
