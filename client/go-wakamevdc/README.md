# Wakame-vdc API Client for golang

Usage:

```
package main

import (
	"fmt"
	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
)
	
func main() {
	c := wakamevdc.NewClient(nil, nil)

	// Create SSH Key Pair
	sshkey, _, err := c.SshKey.Create(&wakamevdc.SshKeyCreateParams{})
	if err != nil {
		fmt.Println("Error: %s\n", err)
		return
	}
	fmt.Printf("SshKey created: %s\n", sshkey.ID)
	c.SshKey.Delete(sshkey.ID)
	
	// Create instance.
	inst, _, err := c.Instance.Create(&wakamevdc.InstanceCreateParams{
		Hypervisor: "kvm",
		CPUCores:   1,
		MemorySize: 1024,
		ImageID:    "wmi-centos1d64",
		VIFs: map[string]wakamevdc.InstanceCreateVIFParams{
			"eth0": {NetworkID: "nw-demo1"},
		},
	})
	
	fmt.Println(inst)
	c.Instance.Delete(inst.ID)
}
```
