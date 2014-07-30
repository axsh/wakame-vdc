# -*- coding: utf-8 -*-

require 'spec_helper'

require "rack"
require "rack/test"

def body
  JSON.parse(last_response.body)
end

RSpec.configure do |c|
  c.include Rack::Test::Methods
end

def app
  Dcmgr::Endpoints::V1203::CoreAPI
end
