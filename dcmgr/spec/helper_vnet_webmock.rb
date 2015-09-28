# -*- coding: utf-8 -*-

require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

def stub_vnet_request(api_suffix, params)
  expected_param_list = params.keys.map(&:to_s).join(",")
  uri = Addressable::Template.new("localhost:9090/api/1.0/#{api_suffix}.json{?#{expected_param_list}}")
  stub_request(:post, uri).to_return(:body => "{\"uuid\":\"#{params[:uuid]}\"}")
end
