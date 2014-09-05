# -*- coding: utf-8 -*-

require 'spec_helper'

require "rack"
require "rack/test"

M = Dcmgr::Models
C = Dcmgr::Constants

#
# Stub methods
#

#TODO: Move stubs to a module

# The API uses this to initialize Isono messaging and raises an error if it
# returns a falsy value. Just stub it out and make it return a truey value.
def stub_dcmgr_syncronized_message_ready
  allow(::Dcmgr).to receive(:syncronized_message_ready).and_return(true)
end

# Some APIs will require certain host nodes to be online. Isono takes care of
# determining which host nodes are online. Since we don't have isono in the unit
# tests, this stub method allows testers to supply their own Sequel::Dataset
# containing the online nodes.
def stub_online_host_nodes(mock_online_nodes)
  allow(M::HostNode).to receive(:online_nodes).and_return(mock_online_nodes)
end

# The Dcmgr.messaging method is used by the API to send messages over AMQP to
# collector. Of course the unit tests will not be running an AMQP exchange so
# we stub this out.
#
# The test double is returned so we can write tests that expect certain methods
# to be called on this object. This way we can test if the correct messages are
# being sent to the collector
def stub_dcmgr_messaging
  msg_double = double("messaging")

  allow(::Dcmgr).to receive(:messaging).and_return(msg_double)

  msg_double
end

def suppress_error_logging
  Dcmgr::Logger::CustomLogger.any_instance.stub(:error)
end

#
# Helper methods
#

def body
  JSON.parse(last_response.body)
end

#TODO: Move this to a module
def it_returns_error(error, http_status = nil, message = nil)
  it "returns error #{error}" do
    expect(body['error']).to eq "Dcmgr::Endpoints::Errors::#{error}"
  end

  if http_status
    it "fails with http status #{http_status}" do
      expect(last_response.status).to eq http_status
    end
  end

  if message
    it "has error message: #{message}" do
      expect(body['message']).to eq message
    end
  end
end

def it_does_not_crash
  it "doesn't crash" do
    expect(last_response.body).not_to eq "<h1>Internal Server Error</h1>"
  end
end

#
# Rack/test setup
#

def app
  Dcmgr::Endpoints::V1203::CoreAPI
end



RSpec.configure do |c|
  c.include Rack::Test::Methods
end
