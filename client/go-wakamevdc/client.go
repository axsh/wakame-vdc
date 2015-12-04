package wakamevdc

import (
	"fmt"
	"net/http"
	"net/url"

	"github.com/dghubble/sling"
)

const (
	libraryVersion = "0.1.0"
	defaultBaseURL = "http://localhost:9001/api/12.03/"
	userAgent      = "go-wakamevdc/" + libraryVersion
	mediaType      = "application/json"

	headerVDCAccountID = "X-VDC-Account-UUID"
)

type StateCompare interface {
	CompareState(id string, state string) (bool, error)
}

// Client manages communication with Wakame-vdc API.
type Client struct {
	sling         *sling.Sling
	accountID     string
	Instance      *InstanceService
	SecurityGroup *SecurityGroupService
	SshKey        *SshKeyService
	Image         *ImageService
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
	c.Image = &ImageService{client: c}
	return c
}

func (c *Client) Sling() *sling.Sling {
	return c.sling.New()
}

type APIError struct {
	ErrorType string `json:"error"`
	Message   string `json:"message"`
	Code      string `json:"code"`
}

func (e *APIError) Error() string {
	return fmt.Sprintf("Type: %s, Code: %s, Message: %s", e.ErrorType, e.Code, e.Message)
}

type errorRaiser func(apiErr *APIError) (*http.Response, error)

/* Utility that helps to handle API error.
Example:
resp, err := trapAPIError(func(apiErr *APIError) (*http.Response, error) {
  return s.client.Sling().Post(SecurityGroupPath).BodyForm(req).Receive(secg, apiErr)
})
*/
func trapAPIError(fn errorRaiser) (*http.Response, error) {
	apiErr := &APIError{}
	resp, err := fn(apiErr)
	if err == nil {
		if code := resp.StatusCode; 400 <= code {
			err = fmt.Errorf("API Error: %s, (HTTP %d)", apiErr.Error(), code)
		}
	}
	return resp, err
}
