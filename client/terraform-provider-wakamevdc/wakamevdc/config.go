package wakamevdc

import (
  "github.com/axsh/wakame-vdc/client/go-wakamevdc"
  "net/url"
)

type Config struct {
  APIEndpoint string
}

func (c *Config) Client() (*wakamevdc.Client, error) {
  //TODO: Don't force the user to include /api/12.03
  baseURL, err := url.Parse(c.APIEndpoint)
  client :=  wakamevdc.NewClient(baseURL, nil)

  return client, err
}
