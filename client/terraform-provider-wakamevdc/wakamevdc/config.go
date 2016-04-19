package wakamevdc

import (
	"net/url"

	"github.com/axsh/wakame-vdc/client/go-wakamevdc"
)

type Config struct {
	APIEndpoint string
}

func (c *Config) Client() (*wakamevdc.Client, error) {
	//TODO: Don't force the user to include /api/12.03
	baseURL, err := url.Parse(c.APIEndpoint)
	if err != nil {
		return nil, err
	}
	client := wakamevdc.NewClient(baseURL, nil)

	return client, err
}
