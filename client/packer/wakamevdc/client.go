package wakamevdc

import (
	"bytes"
	"encoding/json"
  "net/http"
	"net/url"
  /*
  "fmt"
	"io"
	"io/ioutil"
	"reflect"
	"strconv"
	"time"

	"github.com/google/go-querystring/query"
  */
)

const (
	libraryVersion = "0.1.0"
	defaultBaseURL = "https://localhost:9001/api/1203"
	userAgent      = "go-wakamevdc/" + libraryVersion
	mediaType      = "application/json"

	headerRateLimit     = "X-RateLimit-Limit"
)

// Client manages communication with DigitalOcean V2 API.
type Client struct {
	// HTTP client used to communicate with the DO API.
	client *http.Client

	// Base URL for API requests.
	BaseURL *url.URL

  // UserAgent name
  UserAgent string
}

func NewClient(httpClient *http.Client) *Client {
	if httpClient == nil {
		httpClient = http.DefaultClient
	}

  baseURL, _ := url.Parse(defaultBaseURL)

  c := &Client{client: httpClient, BaseURL: baseURL, UserAgent: userAgent}
  return c
}

func (c *Client) Request(http_method, api_path string, body interface{}) (*http.Response, error) {
  rel, err := url.Parse(api_path)
  if err != nil {
    return nil, err
  }
  u := c.BaseURL.ResolveReference(rel)
  buf := new(bytes.Buffer)
	if body != nil {
		err := json.NewEncoder(buf).Encode(body)
		if err != nil {
			return nil, err
		}
	}
  req, err := http.NewRequest(http_method, u.String(), buf)
	if err != nil {
		return nil, err
	}

	req.Header.Add("Content-Type", mediaType)
	req.Header.Add("Accept", mediaType)
	req.Header.Add("User-Agent", userAgent)

  resp, err := c.client.Do(req)
  if err != nil {
		return nil, err
	}

  defer func() {
    if rerr := resp.Body.Close(); err == nil {
      err = rerr
    }
  }()

  return resp, nil
}
