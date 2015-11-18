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

func resourceWakamevdcInstance() *schema.Resource {
	return &schema.Resource{
    Schema: map[string]*schema.Schema{
      "image_id": &schema.Schema{
        Type:     schema.TypeString,
        Required: true,
      },

      "state": &schema.Schema{
        Type:     schema.TypeString,
        Computed: true,
      },

      "display_name": &schema.Schema{
        Type:     schema.TypeString,
        Optional: true,
        ForceNew: true,
      },

      "ssh_keys": &schema.Schema{
        Type:     schema.TypeList,
        Optional: true,
        Elem:     &schema.Schema{Type: schema.TypeString},
      },

      "user_data": &schema.Schema{
        Type:     schema.TypeString,
        Optional: true,
        ForceNew: true,
      },
    },
  }
}
