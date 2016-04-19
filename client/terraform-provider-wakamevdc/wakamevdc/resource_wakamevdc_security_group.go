package wakamevdc

import (
	"fmt"
	"log"

	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceWakamevdcSecurityGroup() *schema.Resource {
	return &schema.Resource{
		Create: resourceWakamevdcSecurityGroupCreate,
		Read:   resourceWakamevdcSecurityGroupRead,
		Update: resourceWakamevdcSecurityGroupUpdate,
		Delete: resourceWakamevdcSecurityGroupDelete,

		Schema: map[string]*schema.Schema{
			"id": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			//TODO: Test this! There's no account in the api client
			"account_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"display_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"description": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"rules": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
		},
	}
}

func resourceWakamevdcSecurityGroupCreate(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	params := wakamevdc.SecurityGroupCreateParams{
		Rules:       d.Get("rules").(string),
		DisplayName: d.Get("display_name").(string),
		Description: d.Get("description").(string),
	}

	sg, _, err := client.SecurityGroup.Create(&params)
	if err != nil {
		return fmt.Errorf("Error creating security group: %s", err)
	}
	d.SetId(sg.ID)
	log.Printf("[INFO] Security Group ID: %s", d.Id())

	return resourceWakamevdcSecurityGroupRead(d, m)
}

func resourceWakamevdcSecurityGroupRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	sg, _, err := client.SecurityGroup.GetByID(d.Id())
	if err != nil {
		return err
	}

	d.Set("display_name", sg.DisplayName)
	return err
}

func resourceWakamevdcSecurityGroupUpdate(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	params := wakamevdc.SecurityGroupUpdateParams{
		Description: d.Get("description").(string),
		DisplayName: d.Get("display_name").(string),
		Rules:       d.Get("rules").(string),
	}

	_, err := client.SecurityGroup.Update(d.Id(), &params)

	return err
}

func resourceWakamevdcSecurityGroupDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	_, err := client.SecurityGroup.Delete(d.Id())
	if err != nil {
		return err
	}
	return nil
}
