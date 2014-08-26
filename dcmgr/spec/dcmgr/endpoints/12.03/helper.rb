# -*- coding: utf-8 -*-

require 'spec_helper'

require "rack"
require "rack/test"

#
# Stub methods
#

def stub_dcmgr_syncronized_message_ready
  allow(::Dcmgr).to receive(:syncronized_message_ready).and_return(true)
end

def stub_online_host_nodes
  mock_online_nodes = M::HostNode.where(id: online_kvm_host_node.id)
  allow(M::HostNode).to receive(:online_nodes).and_return(mock_online_nodes)
end

def stub_dcmgr_messaging
  msg_double = double("messaging")
  allow(msg_double).to receive(:submit)

  allow(::Dcmgr).to receive(:messaging).and_return(msg_double)
end

#
# Helper methods
#

def body
  JSON.parse(last_response.body)
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
