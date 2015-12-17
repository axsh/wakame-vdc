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
	defaultAccountID   = "a-shpoolxx"
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
	Network       *NetworkService
	DCNetwork     *DCNetworkService
}

func NewClient(baseURL *url.URL, httpClient *http.Client) *Client {
	if baseURL == nil {
		baseURL, _ = url.Parse(defaultBaseURL)
	}

	sl := sling.New().Base(baseURL.String()).Client(httpClient)
	sl.Add("User-Agent", userAgent)
	c := &Client{sling: sl, accountID: defaultAccountID}
	c.Instance = &InstanceService{client: c}
	c.SecurityGroup = &SecurityGroupService{client: c}
	c.SshKey = &SshKeyService{client: c}
	c.Image = &ImageService{client: c}
	c.Network = &NetworkService{client: c}
	c.DCNetwork = &DCNetworkService{client: c}
	return c
}

// AccountID is a chain method to set Account ID for the API request.
func (c *Client) AccountID(accountID string) *Client {
	c.accountID = accountID
	return c
}

// Sling returns new Sling object which is configured to access to the API Endpoint.
func (c *Client) Sling() *sling.Sling {
	return c.sling.New().Set(headerVDCAccountID, c.accountID)
}

type ErrorResponse struct {
	ErrorType string `json:"error"`
	Message   string `json:"message"`
	Code      string `json:"code"`
}

// APIError is the response to show error from server.
type APIError struct {
	HTTPStatus int
	ErrorBody  ErrorResponse
}

func (e *APIError) Error() string {
	return fmt.Sprintf("API Error: HTTP Status: %d, Type: %s, Code: %s, Message: %s",
		e.HTTPStatus, e.ErrorBody.ErrorType, e.ErrorBody.Code, e.ErrorBody.Message)
}

func (e *APIError) ErrorType() string {
	return e.ErrorBody.ErrorType
}

func (e *APIError) Code() string {
	return e.ErrorBody.Code
}

func (e *APIError) Message() string {
	return e.ErrorBody.Message
}

type errorRaiser func(errResp *ErrorResponse) (*http.Response, error)

/* Utility that helps to handle API error.
Example:
resp, err := trapAPIError(func(apiErr *APIError) (*http.Response, error) {
  return s.client.Sling().Post(SecurityGroupPath).BodyForm(req).Receive(secg, apiErr)
})
*/
func trapAPIError(fn errorRaiser) (*http.Response, error) {
	errResp := ErrorResponse{}
	resp, err := fn(&errResp)
	if err == nil {
		if code := resp.StatusCode; 400 <= code {
			err = &APIError{
				HTTPStatus: code,
				ErrorBody:  errResp,
			}
		}
	}
	return resp, err
}

type ListRequestParams struct {
	Start int `url:"start,omitempty"`
	Limit int `url:"limit,omitempty"`
}
