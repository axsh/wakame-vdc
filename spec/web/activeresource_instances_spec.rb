# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/../spec_helper'

describe "instance access by active resource" do
  include ActiveResourceHelperMethods
  
  def init
    reset_db

    @class = describe_activeresource_model :Instance
    @physical_host_class = describe_activeresource_model :PhysicalHost
    @name_tag_class = describe_activeresource_model :NameTag
    @auth_tag_class = describe_activeresource_model :AuthTag
    @user_class = describe_activeresource_model :User
    @user = @user_class.find(:myself)
    image_storage_host_a = ImageStorageHost.create
    ImageStorage.create(:image_storage_host=>image_storage_host_a)
    @image_storage = ImageStorage.create(:image_storage_host=>image_storage_host_a)
  end
  
  before(:all) do
    init
  end
    
  before(:each) do
    Account.create(:name=>'account1')
    PhysicalHost.destroy
    @physical_host_a = PhysicalHost.create(:cpus=>4, :cpu_mhz=>1.0,
                                          :memory=>2.0,
                                          :hypervisor_type=>'xen')
    PhysicalHost[@physical_host_a.id].remove_tag(Tag::SYSTEM_TAG_GET_READY_INSTANCE)
    @physical_host_b = PhysicalHost.create(:cpus=>2, :cpu_mhz=>1.6,
                                          :memory=>1.0,
                                          :hypervisor_type=>'xen')
    PhysicalHost[@physical_host_b.id].remove_tag(Tag::SYSTEM_TAG_GET_READY_INSTANCE)
    @physical_host_c = PhysicalHost.create(:cpus=>1, :cpu_mhz=>2.0,
                                          :memory=>4.0,
                                          :hypervisor_type=>'xen')
    PhysicalHost[@physical_host_c.id].remove_tag(Tag::SYSTEM_TAG_GET_READY_INSTANCE)
    
    @account_class = describe_activeresource_model :Account
    @account = @account_class.create(:name=>'test account by instance spec')
    
    @normal_tag_a = @name_tag_class.create(:name=>'tag a', :account=>@account.id) # name tag
    @normal_tag_b = @name_tag_class.create(:name=>'tag b', :account=>@account.id)
    @normal_tag_c = @name_tag_class.create(:name=>'tag c', :account=>@account.id)
    
    instance_crud_auth_tag = @auth_tag_class.create(:name=>'instance crud',
                                                    :role=>0,
                                                    :tags=>[@normal_tag_a.id,
                                                            @normal_tag_b.id],
                                                    :account=>@account.id) # auth tag
    @user.put(:add_tag, :tag=>instance_crud_auth_tag.id)
    
    HvController.destroy
    @hv_controller = HvController.create(:physical_host=>@physical_host_a,
                                         :ip=>'192.168.1.10')
    HvAgent.destroy
    @hv_agent_a = HvAgent.create(:hv_controller=>@hv_controller,
                                 :physical_host=>@physical_host_a,
                                 :ip=>'192.168.1.20')
    @hv_agent_b = HvAgent.create(:hv_controller=>@hv_controller,
                                 :physical_host=>@physical_host_a,
                                 :ip=>'192.168.1.30')
    @hv_agent_c = HvAgent.create(:hv_controller=>@hv_controller,
                                 :physical_host=>@physical_host_a,
                                 :ip=>'192.168.1.40')
  end

  it "should not schedule instances while no runnning physical hosts" do
    [@physical_host_a, @physical_host_b, @physical_host_c].each{|host|
      TagMapping.create(:tag_id=>Tag::SYSTEM_TAG_GET_READY_INSTANCE.id,
                        :target_type=>TagMapping::TYPE_PHYSICAL_HOST,
                        :target_id=>PhysicalHost[host.id].id)
    }
                        
    lambda {
      @class.create(:account=>@account.id,
                    :need_cpus=>1,
                    :need_cpu_mhz=>0.5,
                    :need_memory=>1.0,
                    :image_storage=>@image_storage.uuid)
      
    }.should raise_error(ActiveResource::BadRequest)
  end

  it "should create instance" do
    @physical_host_class.find(@physical_host_a.uuid).put(:remove_tag,
                                                       :tag=>Tag::SYSTEM_TAG_GET_READY_INSTANCE.uuid)
    $instance_a = @class.create(:account=>@account.id,
                                :need_cpus=>1,
                                :need_cpu_mhz=>0.5,
                                :need_memory=>1.0,
                                :image_storage=>@image_storage.uuid)

    $instance_a.status.should == Instance::STATUS_TYPE_OFFLINE
    $instance_a.account.should == @account.id

    real_inst = Instance[$instance_a.id]
    real_inst.hv_agent.physical_host_id.should > 0
  end

  it "should schedule instances by schedule algorithm 2" do
    pending
    Dcmgr::scheduler = Dcmgr::PhysicalHostScheduler::Algorithm2
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

  it "should schedule instances by schedule algorithm 1" do
    Dcmgr::scheduler = Dcmgr::PhysicalHostScheduler::Algorithm1
    
    # physical hosts
    # id / cpus / mhz / memory
    # 1  / 4    / 1.0  / 2.0 / 1F
    # 2  / 2    / 1.6  / 1.0 / 2F
    # 3  / 1    / 2.0  / 4.0 / 3F
    
    # already 'instance a' use physical host 1 in should create instance
    
    pending
    hosts = {}; hosts.default = 0
    3.times{
      hosts[@class.create(:account=>@account.id,
                          :need_cpus=>1,
                          :need_cpu_mhz=>1.0,
                          :need_memory=>1.0).physical_host] += 1
    }
    
    # each floor physica hosts
    hosts.length.should == 3
    hosts[PhysicalHost[1].uuid].should == 1
    hosts[PhysicalHost[2].uuid].should == 2
    hosts[PhysicalHost[3].uuid].should == 3
  end

  it "should run instance" do
    hvchttp = Dcmgr::HvcHttpMock.new(HvController[:ip=>'192.168.1.10'])
    Dcmgr::set_hvcsrv hvchttp
    
    $instance_a = @class.create(:account=>@account.id,
                                :need_cpus=>1,
                                :need_cpu_mhz=>0.5,
                                :need_memory=>0.5,
                                :image_storage=>@image_storage.uuid)

    $instance_a.put(:run)
    $instance_a = @class.find($instance_a.id)
    $instance_a.status.should == Instance::STATUS_TYPE_RUNNING
    
    real_inst = Instance[$instance_a.id]
    hvchttp.hvas[real_inst.hv_agent.ip].instances[real_inst.ip][1].should == :online
  end

  it "should shutdown, and auth check" do
    pending
    instance = @class.create(:account=>@account.id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    instance.should be_true

    instance.put(:add_tag, :tag=>@normal_tag_a)
    instance.put(:shutdown)
    
    pending("check hvc mock server's status")
    
    instance = @class.create(:account=>@account.id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    instance.put(:add_tag, :tag=>@normal_tag_c)
    
    lambda {
     instance.put(:shutdown)
    }.should raise_error(ActiveResource::BadRequest)
  end

  it "shoud shutdown by sample data, and raise role error" do
    pending
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
    pending
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
    instance.user.length.should > 0
  end

  it "shoud get instance details"
    #instance.physicalhost_id.should == 10
    #instance.imagestorage_id.should == 100
    #instance.hvspec_id.should == 10

  it "should reboot" do
    instance = @class.find($instance_a.id)
    instance.put(:reboot)
    pending("check hvc mock server's status")
  end
  
  it "should terminate" do
    instance = @class.find($instance_a.id)
    instance.put(:terminate)
    pending("check hvc mock server's status")
  end
  
  it "should get describe" do
    list = @class.find(:all)
    list.index { |ins| ins.id == $instance_a.id }.should be_true
  end
  
  it "should snapshot image, and backup image to image storage" do
    pending
    instance = @class.create(:account=>@account.id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    
    instance.put(:snapshot)
  end
  
  it "should shutdown by sample data" do
    reset_db
    real_instance = Instance[1]
    instance = @class.find(real_instance.uuid)
    instance.should be_true
    instance.put(:add_tag, :tag=>@normal_tag_a)
    instance.put(:shutdown)
    init
  end
end

