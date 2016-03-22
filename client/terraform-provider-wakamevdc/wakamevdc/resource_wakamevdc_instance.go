package wakamevdc

import (
	"fmt"
	"log"
	"time"

	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceWakamevdcInstance() *schema.Resource {
	return &schema.Resource{
		Create: resourceWakamevdcInstanceCreate,
		Read:   resourceWakamevdcInstanceRead,
		Update: resourceWakamevdcInstanceUpdate,
		Delete: resourceWakamevdcInstanceDelete,

		Schema: map[string]*schema.Schema{
			"image_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"cpu_cores": &schema.Schema{
				Type:     schema.TypeInt,
				Required: true,
				ForceNew: true,
			},

			"memory_size": &schema.Schema{
				Type:     schema.TypeInt,
				Required: true,
				ForceNew: true,
			},

			"hypervisor": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"host_node_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"state": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"status": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"display_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"ssh_key_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"user_data": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"vif": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"id": &schema.Schema{
							Type:     schema.TypeString,
							Computed: true,
						},

						"network_id": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},

						"ip_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},

						"security_groups": &schema.Schema{
							Type:     schema.TypeList,
							Optional: true,
							Elem: &schema.Schema{
								Type: schema.TypeString,
							},
						},
					},
				},
			},
		},
	}
}

func resourceWakamevdcInstanceCreate(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)
	var vifs map[string]wakamevdc.InstanceCreateVIFParams

	if v := d.Get("vif"); v != nil {
		vifs = make(map[string]wakamevdc.InstanceCreateVIFParams)

		for i, vifMapInterface := range v.([]interface{}) {
			vifMap := vifMapInterface.(map[string]interface{})

			vifStruct := wakamevdc.InstanceCreateVIFParams{
				NetworkID:   vifMap["network_id"].(string),
				IPv4Address: vifMap["ip_address"].(string),
			}

			if vifMap["security_groups"] != nil {
				securityGroupIDsI := vifMap["security_groups"].([]interface{})
				securityGroupIDs := make([]string, len(securityGroupIDsI))

				for i, securityGroupID := range securityGroupIDsI {
					securityGroupIDs[i] = securityGroupID.(string)
				}

				vifStruct.SecurityGroupIDs = securityGroupIDs
			}

			key := fmt.Sprintf("eth%v", i)
			vifs[key] = vifStruct
		}
	}

	params := &wakamevdc.InstanceCreateParams{
		CPUCores:    d.Get("cpu_cores").(int),
		MemorySize:  d.Get("memory_size").(int),
		Hypervisor:  d.Get("hypervisor").(string),
		HostNodeID:  d.Get("host_node_id").(string),
		SshKeyID:    d.Get("ssh_key_id").(string),
		ImageID:     d.Get("image_id").(string),
		DisplayName: d.Get("display_name").(string),
		UserData:    d.Get("user_data").(string),
		VIFs:        vifs,
	}

	inst, _, err := client.Instance.Create(params)
	if err != nil {
		return fmt.Errorf("Error creating instance: %s", err)
	}
	d.SetId(inst.ID)
	log.Printf("[INFO] Instance ID: %s", d.Id())

	stateConf := &resource.StateChangeConf{
		Pending:    []string{"scheduling", "initializing", "pending", "starting"},
		Target:     "running",
		Refresh:    InstanceStateRefreshFunc(client, d.Id()),
		Timeout:    10 * time.Minute,
		Delay:      10 * time.Second,
		MinTimeout: 3 * time.Second,
	}

	_, err = stateConf.WaitForState()
	if err != nil {
		return fmt.Errorf(
			"Error waiting for instance (%s) to running: %s", d.Id(), err)
	}

	return resourceWakamevdcInstanceRead(d, m)
}

func resourceWakamevdcInstanceRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	inst, _, err := client.Instance.GetByID(d.Id())
	if err != nil {
		return err
	}

	d.Set("display_name", inst.DisplayName)
	d.Set("state", inst.State)
	d.Set("status", inst.Status)
	d.Set("host_node_id", inst.HostNodeID)

	vifs := make([]map[string]interface{}, len(inst.VIFs))
	for i, vif := range inst.VIFs {
		vifs[i] = make(map[string]interface{})
		vifs[i]["id"] = vif.ID
		vifs[i]["network_id"] = vif.NetworkID
		vifs[i]["ip_address"] = vif.IPv4.Address
		vifs[i]["security_groups"] = vif.SecurityGroupIDs
	}
	d.Set("vif", vifs)

	return err
}

func resourceWakamevdcInstanceUpdate(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	params := wakamevdc.InstanceUpdateParams{
		DisplayName: d.Get("display_name").(string),
	}

	_, err := client.Instance.Update(d.Id(), &params)
	if err != nil {
		return err
	}

	return nil
}

func resourceWakamevdcInstanceDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*wakamevdc.Client)

	log.Printf("[INFO] Terminating instance: %s", d.Id())

	_, err := client.Instance.Delete(d.Id())
	if err != nil {
		if apiErr, ok := err.(*wakamevdc.APIError); ok {
			// API Error: HTTP Status: 400, Type: Dcmgr::Endpoints::Errors::InvalidInstanceState, Code: 125, Message: terminated
			if apiErr.Code() == "125" {
				log.Printf("Instance is in unexpected state. %s", err)
				return nil
			}
		}
		return err
	}

	stateConf := &resource.StateChangeConf{
		Pending:    []string{"scheduling", "pending", "starting", "running", "shuttingdown", "halted", "stopping"},
		Target:     "terminated",
		Refresh:    InstanceStateRefreshFunc(client, d.Id()),
		Timeout:    10 * time.Minute,
		Delay:      10 * time.Second,
		MinTimeout: 3 * time.Second,
	}

	_, err = stateConf.WaitForState()
	if err != nil {
		return fmt.Errorf(
			"Error waiting for instance (%s) to terminate: %s", d.Id(), err)
	}

	return nil
}

func InstanceStateRefreshFunc(client *wakamevdc.Client, instanceID string) resource.StateRefreshFunc {
	return func() (interface{}, string, error) {
		inst, _, err := client.Instance.GetByID(instanceID)
		if err != nil {
			log.Printf("[ERROR]: InstanceStateRefresh(): %s", err)
			return nil, "", err
		}
		return inst, inst.State, nil
	}
}
