# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe "physical host access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :PhysicalHost
  end
  
  it "should add" do
    physicalhost = @class.create(:cpus=>4,
                                 :cpu_mhz=>1.0,
                                 :memory=>2.0,
                                 :hypervisor_type=>'xen')
    physicalhost.id.length.should > 0
    
    real_physicalhost = PhysicalHost[physicalhost.id]
    p real_physicalhost.id
    real_physicalhost.should be_valid
    real_physicalhost.id.should > 0
    real_physicalhost.uuid.length.should > 0
    real_physicalhost.cpus.should == 4
    real_physicalhost.cpu_mhz.should == 1.0
    real_physicalhost.memory.should == 2.0
    real_physicalhost.hypervisor_type.should == 'xen'
    real_physicalhost.tags.each{|tag| p tag}
    real_physicalhost.tags.include?(Tag::SYSTEM_TAG_GET_READY_INSTANCE).should be_true
    $physicalhost_id = physicalhost.id
  end

  it "should remove tag"

  it "should get list" do
    list = @class.find(:all)
    list.index { |ph| ph.id == $physicalhost_id }.should be_true
  end
  
  it "should delete" do
    id = $physicalhost_id
    lambda {
      @class.find(id).destroy
    }.should change{ PhysicalHost[id] }
  end
  
  it "should relate user" do
    physicalhost = @class.create(:cpus=>4,
                                 :cpu_mhz=>1.0,
                                 :memory=>2.0,
                                 :hypervisor_type=>'xen')
    p physicalhost.id
    user = User.create(:name=>'__test_activeresource_physicalhost_spec__', :password=>'passwd')
    
    physicalhost.put(:relate, :user=>user.uuid)

    @class.find(physicalhost.id).relate_user.should == user.uuid
  end
end


