package wakamevdc

import (
  /*
  "fmt"
  "log"
  "strconv"
  "strings"
  "time"
  */

  //"github.com/axsh/wakame-vdc/client/go-wakamevdc"
  //"github.com/hashicorp/terraform/helper/resource"
  "github.com/hashicorp/terraform/helper/schema"
)

func resourceWakamevdcSSHKey() *schema.Resource {
  return &schema.Resource{
    Create: resourceWakamevdcSSHKeyCreate,
    Read: resourceWakamevdcSSHKeyRead,
    Update: resourceWakamevdcSSHKeyUpdate,
    Delete: resourceWakamevdcSSHKeyDelete,

    Schema: map[string]*schema.Schema{
      "id": &schema.Schema{
        Type:     schema.TypeString,
        Computed: true,
      },

      "name": &schema.Schema{
        Type:     schema.TypeString,
        Required: true,
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
  return nil
}

func resourceWakamevdcSSHKeyRead(d *schema.ResourceData, m interface{}) error {
  return nil
}

func resourceWakamevdcSSHKeyUpdate(d *schema.ResourceData, m interface{}) error {
  return nil
}

func resourceWakamevdcSSHKeyDelete(d *schema.ResourceData, m interface{}) error {
  return nil
}
