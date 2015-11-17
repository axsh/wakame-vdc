package wakamevdc

import (
	"testing"
)

func TestNewClient(t *testing.T) {
	c := NewClient(nil)
	if c.BaseURL.String() != defaultBaseURL {
		t.Errorf("NewClient BaseURL = %v, expected %v", c.BaseURL.String(), defaultBaseURL)
	}

	if c.UserAgent != userAgent {
		t.Errorf("NewClick UserAgent = %v, expected %v", c.UserAgent, userAgent)
	}
}
