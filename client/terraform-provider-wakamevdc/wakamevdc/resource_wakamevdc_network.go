package wakamevdc

import (
	"fmt"
	"log"

	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceWakamevdcNetwork() *schema.Resource {
	return &schema.Resource{
		Create: resourceWakamevdcNetworkCreate,
		Read:   resourceWakamevdcNetworkRead,
		Update: resourceWakamevdcNetworkUpdate,
		Delete: resourceWakamevdcNetworkDelete,

		Schema: map[string]*schema.Schema{
			"id": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"account_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"service_type": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"display_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"description": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"ipv4_network": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"prefix": &schema.Schema{
				Type:     schema.TypeInt,
				Required: true,
			},

			"network_mode": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"dc_network_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"dc_network_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"ipv4_gw": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"editable": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				Default:  false,
			},

			"metric": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
				Computed: true,
			},

			"ip_assignment": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},
		},
	}
}

func resourceWakamevdcNetworkCreate(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	metric, ok := d.GetOk("metric")
	if ok && metric.(int) < 0 {
		return fmt.Errorf("metric can not be less than zero")
	}

	params := wakamevdc.NetworkCreateParams{
		IPv4Network:  d.Get("ipv4_network").(string),
		Prefix:       d.Get("prefix").(int),
		NetworkMode:  d.Get("network_mode").(string),
		IPAssignment: d.Get("ip_assignment").(string),
		IPv4GW:       d.Get("ipv4_gw").(string),
		Editable:     d.Get("editable").(bool),
		DisplayName:  d.Get("display_name").(string),
		Description:  d.Get("description").(string),
	}

	if _, ok := d.GetOk("dc_network_id"); ok {
		params.DCNetworkID = d.Get("dc_network_id").(string)
	} else if dcnName, ok := d.GetOk("dc_network_name"); ok {
		dcnList, _, err := client.DCNetwork.List(nil, dcnName.(string))
		if err != nil {
			return err
		}
		if len(dcnList.Results) < 1 {
			return fmt.Errorf("Unknown dc_network_name: %s", dcnName.(string))
		}
		params.DCNetworkID = dcnList.Results[0].ID
		d.Set("dc_network_id", params.DCNetworkID)
	} else {
		return fmt.Errorf("Either dc_network_id or dc_network_name has to be specified")
	}

	nw, _, err := client.Network.Create(&params)
	if err != nil {
		return fmt.Errorf("Error creating network: %s", err)
	}
	d.SetId(nw.ID)
	log.Printf("[INFO] Network ID: %s", d.Id())

	// Set computed parameters
	d.Set("ip_assignment", nw.IPAssignment)
	d.Set("metric", nw.Metric)

	return nil
}

func resourceWakamevdcNetworkRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	nw, _, err := client.Network.GetByID(d.Id())
	if err != nil {
		return err
	}

	d.Set("ipv4_network", nw.IPv4Network)
	d.Set("prefix", nw.Prefix)
	d.Set("ipv4_gw", nw.IPv4GW)
	d.Set("network_mode", nw.NetworkMode)
	d.Set("ip_assignment", nw.IPAssignment)
	d.Set("display_name", nw.DisplayName)
	return nil
}

func resourceWakamevdcNetworkUpdate(d *schema.ResourceData, m interface{}) error {
	return nil
}

func resourceWakamevdcNetworkDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	_, err := client.Network.Delete(d.Id())
	if err != nil {
		return err
	}
	return nil
}
