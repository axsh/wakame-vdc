package wakamevdc

import (
	"fmt"
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

func parameterCheckFailed(ParamName string, wakame string, terraform string) error {
	return fmt.Errorf("The field '%s' didn't match.\nWakame-vdc had: '%s'\nTerraform had: '%s'", ParamName, wakame, terraform)
}
