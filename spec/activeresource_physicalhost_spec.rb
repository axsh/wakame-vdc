# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/spec_helper'

describe "physical host access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :PhysicalHost
  end
  
  it "should add" do
    physicalhost = @class.create(:cpu_model=>'core2',
                                 :cpu_mhz=>1.0,
                                 :memory=>1.1,
                                 :location=>'',
                                 :hypervisor_type=>'')
    physicalhost.id.should > 0
    PhysicalHost[physicalhost.id].should be_valid
    $physicalhost_id = physicalhost.id
  end
  
  it "should delete" do
    id = $physicalhost_id
    lambda {
      @class.find(id).destroy
    }.should change{ PhysicalHost[id] }
  end
  
  it "should relate user" do
    physicalhost = @class.create(:cpu_model=>'core2',
                                 :cpu_mhz=>1.0,
                                 :memory=>1.1,
                                 :location=>'',
                                 :hypervisor_type=>'')
    user = User.create(:account=>'__test_activeresource_physicalhost_spec__', :password=>'passwd',
                        :group_id=>1)
    physicalhost.put(:relate, :user=>user.id)
    physicalhost.relation_user.id.should == user.id
  end
end


