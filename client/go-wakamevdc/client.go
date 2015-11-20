package wakamevdc

import (
  "net/http"
	"net/url"
	"github.com/dghubble/sling"
)

const (
	libraryVersion = "0.1.0"
	defaultBaseURL = "http://localhost:9001/api/12.03/"
	userAgent      = "go-wakamevdc/" + libraryVersion
	mediaType      = "application/json"

	headerVDCAccountID     = "X-VDC-Account-UUID"
)

// Client manages communication with Wakame-vdc API.
type Client struct {
  sling *sling.Sling
  accountID string
  Instance  *InstanceService
  SecurityGroup *SecurityGroupService
  SshKey    *SshKeyService
}

func NewClient(baseURL *url.URL, httpClient *http.Client) *Client {
	if baseURL == nil {
		baseURL, _ = url.Parse(defaultBaseURL)
	}

	sl := sling.New().Base(baseURL.String()).Client(httpClient)
	sl.Add("User-Agent", userAgent)
	sl.Add(headerVDCAccountID, "a-shpoolxx")
	c := &Client{sling: sl}
  c.Instance = &InstanceService{client: c}
  c.SecurityGroup = &SecurityGroupService{client: c}
	c.SshKey = &SshKeyService{client: c}
  return c
}

func (c *Client) Sling() *sling.Sling {
	return c.sling.New()
}
