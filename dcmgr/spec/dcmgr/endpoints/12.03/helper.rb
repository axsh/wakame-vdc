# -*- coding: utf-8 -*-

require 'spec_helper'

require "rack"
require "rack/test"

RSpec.configure do |c|
  c.include Rack::Test::Methods
end

def app
  Dcmgr::Endpoints::V1203::CoreAPI
end
