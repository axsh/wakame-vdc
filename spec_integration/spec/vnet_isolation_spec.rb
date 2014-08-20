# -*- coding: utf-8 -*-

require 'spec_helper'

describe 'vnet_isolation' do
  it "creates a network whose mode is virtual" do
    aa = VdcVnetSpec::Network.create("
      network=10.105.0.0
      gw=10.105.0.1
      prefix=24
      metric=10
      domain_name=vdclocal
      network_mode=l2overlay
      ip_assignment=asc
      service_type=std
      display_name=test
      dhcp_range=default
      service_dhcp=10.105.0.1
      dc_network=dcn-cnb31y4y
    ")
  end
end
