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
      assign_count += 1
      assign_count <= 1
    end
    
    p @ipm.assign_ip
    lambda {
      p @ipm.assign_ip
    }.should raise_error(Dcmgr::IP_MANAGER::NoAssignIPError)
  end
end
