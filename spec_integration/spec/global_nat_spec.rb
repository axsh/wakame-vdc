# -*- conding: utf-8 -*-

require 'spec_helper'

feature 'Global NAT' do
  before(:all) do
  end

  scenario 'Release a global IP to an interface' do
    pending 'not implemented yet.'
    fail
    launch_instance
    release_global_ip
    ping_8_8_8_8
    terminate_instance
  end

  scenario 'Detach a global IP from an interface' do
    pending 'not implemented yet.'
    fail
  end

  scenario 'Release fail if an IP is already assigned' do
    pending 'not implemented yet.'
    fail
  end

  scenario 'Release fail if all IPs run out' do
    pending 'not implemented yet.'
    fail
  end
end
