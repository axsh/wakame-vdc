package wakamevdc

import (
	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceWakamevdcSSHKey() *schema.Resource {
	return &schema.Resource{
		Create: resourceWakamevdcSSHKeyCreate,
		Read:   resourceWakamevdcSSHKeyRead,
		Update: resourceWakamevdcSSHKeyUpdate,
		Delete: resourceWakamevdcSSHKeyDelete,

		Schema: map[string]*schema.Schema{
			"id": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"display_name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"description": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"public_key": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"fingerprint": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
		},
	}
}

func resourceWakamevdcSSHKeyCreate(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	params := wakamevdc.SshKeyCreateParams{
		DisplayName: d.Get("display_name").(string),
		Description: d.Get("description").(string),
		PublicKey:   d.Get("public_key").(string),
	}

	key, _, err := client.SshKey.Create(&params)

	d.SetId(key.ID)
	d.Set("fingerprint", key.Fingerprint)

	return err
}

func resourceWakamevdcSSHKeyRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	key, _, err := client.SshKey.GetByID(d.Id())
	if err != nil {
		return err
	}

	d.Set("display_name", key.DisplayName)
	d.Set("public_key", key.PublicKey)
	d.Set("fingerprint", key.Fingerprint)
	return err
}

func resourceWakamevdcSSHKeyUpdate(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	params := wakamevdc.SshKeyUpdateParams{
		DisplayName: d.Get("display_name").(string),
		Description: d.Get("description").(string),
	}

	_, err := client.SshKey.Update(d.Id(), &params)

	return err
}

func resourceWakamevdcSSHKeyDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	_, err := client.SshKey.Delete(d.Id())

	return err
}
