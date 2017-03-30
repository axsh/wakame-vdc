package wakamevdc

import (
	//"os"
	"testing"

	builderT "github.com/mitchellh/packer/helper/builder/testing"
)

func TestBuilderAcc_basic(t *testing.T) {
	builderT.Test(t, builderT.TestCase{
		PreCheck: func() { testAccPreCheck(t) },
		Builder:  &Builder{},
		Template: testBuilderAccBasic,
	})
}

func testAccPreCheck(t *testing.T) {
/*	if v := os.Getenv("WAKAMEVDC_API_ENDPOINT"); v == "" {
		t.Fatal("WAKAMEVDC_API_ENDPOINT must be set for acceptance tests")
	}
*/
}

const testBuilderAccBasic = `
{
	"builders": [{
		"type": "test",
    "api_endpoint": "http://localhost:9001",
		"account_id": "nyc2",
		"image_id": "wmi-centos64"
	}]
}
`
