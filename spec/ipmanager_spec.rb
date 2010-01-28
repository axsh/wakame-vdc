# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::IP_MANAGER do
  before(:each) do
    @ipm = Dcmgr::IP_MANAGER
    @ipm.setup('00:50:56:c0:00:01'=>'192.168.1.1',
               '00:50:56:c0:00:02'=>'192.168.1.2')
  end
  
  it "should assign ip" do
    @ipm.set_assigned? do |mac, ip|
      ip != '192.168.1.2'
    end
    
    @ipm.assign_ip.should == ['00:50:56:c0:00:01', '192.168.1.1']
  end
  
  it "should raise error, when no ip" do
    assign_count = 0
    @ipm.set_assigned? do |mac, ip|
      p "check test #2"
      assign_count += 1
      assign_count <= 1
    end
    
    @ipm.assign_ip
    lambda {
      @ipm.assign_ip
    }.should raise_error(Dcmgr::IP_MANAGER::NoAssignIPError)
    
    @ipm.set_default_assigned?
  end

  it "should get mac address" do
    @ipm.macaddress_by_ip('192.168.1.1').should == '00:50:56:c0:00:01'
    @ipm.macaddress_by_ip('192.168.1.2').should == '00:50:56:c0:00:02'
  end

  after(:all) do
    ips = []; 100.times{|i| ips << ["00:16:%d" % i, "192.168.11.#{i + 200}"]}
    Dcmgr.assign_ips = Hash[*ips.flatten]
    @ipm.set_default_assigned?
    p "set ip manager"
  end
end
