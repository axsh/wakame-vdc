package wakamevdc

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

// Provider returns a schema.Provider for Wakame-vdc.
func Provider() terraform.ResourceProvider {
	return &schema.Provider{
		Schema: map[string]*schema.Schema{
			"api_endpoint": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				DefaultFunc: schema.EnvDefaultFunc("WAKAMEVDC_API_ENDPOINT", nil),
				Description: "Endpoint URL for API.",
			},
		},

		ResourcesMap: map[string]*schema.Resource{
			"wakamevdc_instance":       resourceWakamevdcInstance(),
			"wakamevdc_ssh_key":        resourceWakamevdcSSHKey(),
			"wakamevdc_security_group": resourceWakamevdcSecurityGroup(),
			"wakamevdc_network":        resourceWakamevdcNetwork(),
		},

		ConfigureFunc: providerConfigure,
	}
}

func providerConfigure(d *schema.ResourceData) (interface{}, error) {
	config := Config{
		APIEndpoint: d.Get("api_endpoint").(string),
	}

	return config.Client()
}
