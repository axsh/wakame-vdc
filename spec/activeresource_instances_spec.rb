# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe "instance access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Instance
    @name_tag_class = describe_activeresource_model :NameTag
    @auth_tag_class = describe_activeresource_model :AuthTag
    @user_class = describe_activeresource_model :User
    @user = @user_class.find(:myself)
    
    Account.create(:name=>'account1')
    physical_host_a = PhysicalHost.create(:cpus=>4, :cpu_mhz=>1.0,
                                          :memory=>2.0,
                                          :hypervisor_type=>'xen')
    
    physical_host_b = PhysicalHost.create(:cpus=>2, :cpu_mhz=>1.6,
                                          :memory=>1.0,
                                          :hypervisor_type=>'xen')
    physical_host_c = PhysicalHost.create(:cpus=>1, :cpu_mhz=>2.0,
                                          :memory=>4.0,
                                          :hypervisor_type=>'xen')
    image_storage_host_a = ImageStorageHost.create()
    ImageStorage.create(:image_storage_host=>image_storage_host_a)
    
    @account_class = describe_activeresource_model :Account
    @account = @account_class.create(:name=>'test account by instance spec')
    
    @normal_tag_a = @name_tag_class.create(:name=>'tag a', :account=>@account.id) # name tag
    @normal_tag_b = @name_tag_class.create(:name=>'tag b', :account=>@account.id)
    @normal_tag_c = @name_tag_class.create(:name=>'tag c', :account=>@account.id)
    
    instance_crud_auth_tag = @auth_tag_class.create(:name=>'instance crud',
                                                    :roll=>0,
                                                    :tags=>[@normal_tag_a.id,
                                                            @normal_tag_b.id],
                                                    :account=>@account.id) # auth tag
    @user.put(:add_tag, :tag=>instance_crud_auth_tag.id)
  end

  it "should create instance" do
    $instance_a = @class.create(:account=>@account.id,
                                :need_cpus=>1,
                                :need_cpu_mhz=>0.5,
                                :need_memory=>1.0)

    $instance_a.status.should == Instance::STATUS_TYPE_STOP
    $instance_a.account.should == @account.id

    real_inst = Instance[$instance_a.id]
    real_inst.physical_host_id.should == 1
  end

  it "should schedule instances" do
    # physical hosts
    # id / cpus / mhz / memory
    # 1  / 4    / 1.0  / 2.0 
    # 2  / 2    / 1.6  / 1.0 
    # 3  / 1    / 2.0  / 4.0
    
    # already 'instance a' use physical host 1 in should create instance

    @class.create(:account=>@account.id,
                  :need_cpus=>3,
                  :need_cpu_mhz=>0.5,
                  :need_memory=>1.0).physical_host.should == PhysicalHost[1].uuid

    @class.create(:account=>@account.id,
                  :need_cpus=>1,
                  :need_cpu_mhz=>1.8,
                  :need_memory=>3.5).physical_host.should == PhysicalHost[3].uuid # skip 2
    
    @class.create(:account=>@account.id,
                  :need_cpus=>1,
                  :need_cpu_mhz=>0.8,
                  :need_memory=>0.4).physical_host.should == PhysicalHost[2].uuid
    
    @class.create(:account=>@account.id,
                  :need_cpus=>1,
                  :need_cpu_mhz=>0.8,
                  :need_memory=>0.4).physical_host.should == PhysicalHost[2].uuid
    
  end

  it "should run instance" do
    $instance_a = @class.create(:account=>@account.id,
                                :need_cpus=>1,
                                :need_cpu_mhz=>0.5,
                                :need_memory=>0.5)

    $instance_a.put(:run)
    $instance_a = @class.find($instance_a.id)
    $instance_a.status.should == Instance::STATUS_TYPE_RUNNING
  end

  it "should shutdown, and auth check" do
    instance = @class.create(:account=>@account.id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    instance.should be_true

    instance.put(:add_tag, :tag=>@normal_tag_a)
    instance.put(:shutdown)
    
    instance = @class.create(:account=>@account.id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    instance.put(:add_tag, :tag=>@normal_tag_c)
    
    lambda {
     instance.put(:shutdown)
    }.should raise_error(ActiveResource::BadRequest)
  end

  it "should find tag" do
    instance = @class.create(:account=>@account.id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    
    instance.tags.include?(@normal_tag_c.id).should be_false
    instance.put(:add_tag, :tag=>@normal_tag_c.id)

    instance = @class.find(instance.id)
    instance.tags.include?(@normal_tag_c.id).should be_true

    instance.put(:remove_tag, :tag=>@normal_tag_c.id)
    instance = @class.find(instance.id)
    instance.tags.include?(@normal_tag_c.id).should be_false
  end

  it "should get instance" do
    instance = @class.find($instance_a.id)
    instance.user_id.should > 0
  end

  it "shoud get instance details"
    #instance.physicalhost_id.should == 10
    #instance.imagestorage_id.should == 100
    #instance.hvspec_id.should == 10

  it "should reboot" do
    instance = @class.find($instance_a.id)
    instance.put(:reboot)
  end
  
  it "should terminate" do
    instance = @class.find($instance_a.id)
    instance.put(:terminate)
  end
  
  it "should get describe" do
    list = @class.find(:all)
    list.index { |ins| ins.id == $instance_a.id }.should be_true
  end
  
  it "should snapshot image, and backup image to image storage" do
    instance = @class.create(:account=>@account.id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    
    instance.put(:snapshot)
  end
end

