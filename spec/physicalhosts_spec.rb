# -*- coding: utf-8 -*-

DISABLE_TEST_SERVER = true
require File.dirname(__FILE__) + '/spec_helper'

describe PhysicalHost do
  it "should get schedule instances, not only 'get read instance' tag" do
    physicalhost_a = PhysicalHost.create
    physicalhost_b = PhysicalHost.create
    physicalhost_c = PhysicalHost.create
    
    physicalhost_a.remove_tag(Tag.system_tag(:STANDBY_INSTANCE))
    physicalhost_c.remove_tag(Tag.system_tag(:STANDBY_INSTANCE))

    enable_physicalhosts = PhysicalHost.enable_hosts
    enable_physicalhosts.include?(physicalhost_a).should be_true
    enable_physicalhosts.include?(physicalhost_b).should be_false
    enable_physicalhosts.include?(physicalhost_c).should be_true
  end
end
