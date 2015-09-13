# -*- coding: utf-8 -*-

require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

def request_params(params)
  ret = ""
  params.each do |k,v|
    next if k == :uuid
    next if k == :display_name
    ret = "#{ret}#{k.to_sym}=#{v}&"
  end
  ret.chop!
end

def stub_vnet_request(api_suffix, params)
  uri = Addressable::Template.new("localhost:9090/api/1.0/#{api_suffix}.json?#{request_params(params)}{&other*}")
  stub_request(:post, uri).to_return(:body => "{\"uuid\":\"#{params[:uuid]}\"}")
end
