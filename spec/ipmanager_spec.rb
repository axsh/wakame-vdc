# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::IPManager do
  before(:each) do
    @ipm = Dcmgr::IPManager
  end

  after(:all) do
    @ipm.set_default_assigned?
  end
  
  it "should assign ip" do
    @ipm.set_assigned? do |mac, ip|
      true
    end
    
    ips = @ipm.assign_ips
    ips.length.should == 2

    ips[0][:group_name].should == 'public'
    ips[0][:ip] == '192.168.1.1'
    ips[0][:mac] == '00:00:01'

    ips[1][:group_name].should == 'private'
    ips[1][:ip] == '192.168.11.201'
    ips[1][:mac] == '00:16:01'
  end
  
  it "should raise error, when no ip" do
    assign_count = 0
    @ipm.set_assigned? do |mac, ip|
      assign_count += 1
      assign_count <= 2
    end
    
    @ipm.assign_ips
    lambda {
      @ipm.assign_ips
    }.should raise_error(Dcmgr::IPManager::NoAssignIPError)
    
    @ipm.set_default_assigned?
  end

  it "should get mac address" do
    @ipm.macaddress_by_ip('192.168.1.1').should == '00:50:56:c0:00:01'
    @ipm.macaddress_by_ip('192.168.1.2').should == '00:50:56:c0:00:02'
  end
end
