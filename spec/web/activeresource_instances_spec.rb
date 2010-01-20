# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/../spec_helper'

describe "instance access by active resource" do
  include ActiveResourceHelperMethods
  
  before(:each) do
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
    Instance.destroy
  end

  it "should not schedule instances while no runnning physical hosts" do
    PhysicalHost.each{|host|
      TagMapping.create(:tag_id=>Tag.system_tag(:STANDBY_INSTANCE).id,
                        :target_type=>TagMapping::TYPE_PHYSICAL_HOST,
                        :target_id=>host.id)
    }
                        
    lambda {
      @class.create(:account=>Account[1].uuid,
                    :need_cpus=>1,
                    :need_cpu_mhz=>0.5,
                    :need_memory=>1.0,
                    :image_storage=>ImageStorage[1].uuid)
      
    }.should raise_error(ActiveResource::BadRequest)
  end

  it "should create instance" do
    @physical_host_class.find(PhysicalHost[1].uuid).put(:remove_tag,
                                                       :tag=>Tag.system_tag(:STANDBY_INSTANCE).uuid)
    $instance_a = @class.create(:account=>Account[1].uuid,
                                :need_cpus=>1,
                                :need_cpu_mhz=>0.5,
                                :need_memory=>1.0,
                                :image_storage=>ImageStorage[1].uuid)

    $instance_a.status.should == Instance::STATUS_TYPE_OFFLINE
    $instance_a.account.should == Account[1].uuid

    real_inst = Instance[$instance_a.id]
    real_inst.hv_agent.physical_host_id.should > 0
  end

  it "should schedule instances by schedule algorithm 2" do
    Dcmgr::scheduler = Dcmgr::PhysicalHostScheduler::Algorithm2
    # physical hosts
    # id / cpus / mhz / memory
    # 1  / 4    / 1.0  / 2.0 
    # 2  / 2    / 1.6  / 1.0 
    # 3  / 1    / 2.0  / 4.0
    
    # already 'instance a' use physical host 1 in should create instance
    
    instance = @class.create(:account=>Account[1].uuid,
                             :need_cpus=>3,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>1000,
                             :image_storage=>@image_storage.uuid)
    HvAgent[instance.hv_agent].physical_host == PhysicalHost[1].uuid

    instance = @class.create(:account=>Account[1].uuid,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.7,
                             :need_memory=>2000,
                             :image_storage=>@image_storage.uuid) # skip 2
    HvAgent[instance.hv_agent].physical_host == PhysicalHost[3].uuid
    
    instance = @class.create(:account=>Account[1].uuid,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.8,
                             :need_memory=>400,
                             :image_storage=>@image_storage.uuid)
    HvAgent[instance.hv_agent].physical_host == PhysicalHost[2].uuid
    
    instance = @class.create(:account=>Account[1].uuid,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.8,
                             :need_memory=>400,
                             :image_storage=>@image_storage.uuid)
    HvAgent[instance.hv_agent].physical_host == PhysicalHost[2].uuid
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

  it "should schedule instances, archetype test"
  
  it "should run instance" do
    hvchttp = Dcmgr::HvcHttpMock.new(HvController[:ip=>'192.168.1.10'])
    Dcmgr::hvchttp = hvchttp
    
    $instance_a = @class.create(:account=>Account[1].id,
                                :need_cpus=>1,
                                :need_cpu_mhz=>0.5,
                                :need_memory=>0.5,
                                :image_storage=>ImageStorage[1].uuid)

    $instance_a.put(:run)
    $instance_a = @class.find($instance_a.id)
    $instance_a.status.should == Instance::STATUS_TYPE_RUNNING
    
    real_inst = Instance[$instance_a.id]
    hvchttp.hvas[real_inst.hv_agent.ip].instances[real_inst.ip][1].should == :online
  end

  it "should shutdown, and auth check" do
    pending
    instance = @class.create(:account=>Account[1].id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    instance.should be_true

    instance.put(:add_tag, :tag=>@normal_tag_a)
    instance.put(:shutdown)
    
    pending("check hvc mock server's status")
    
    instance = @class.create(:account=>Account[1].id,
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
    instance = @class.create(:account=>Account[1].id,
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
    instance = @class.create(:account=>Account[1].id,
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
    instance_a = Instance.create(:status=>0, # offline
                                 :account=>Account[1],
                                 :user=>User[1],
                                 :image_storage=>ImageStorage[1],
                                 :need_cpus=>1,
                                 :need_cpu_mhz=>0.5,
                                 :need_memory=>500,
                                 :hv_agent=>HvAgent[1],
                                 :ip=>'192.168.2.100')
    instance = @class.find(instance_a.uuid)
    instance.user.length.should > 0
    instance.image_storage.length.should > 0
  end

  it "should reboot" do
    real_instance = Instance.create(:status=>0, # offline
                                    :account=>Account[1],
                                    :user=>User[1],
                                    :image_storage=>ImageStorage[1],
                                    :need_cpus=>1,
                                    :need_cpu_mhz=>0.5,
                                    :need_memory=>500,
                                    :hv_agent=>HvAgent[1],
                                    :ip=>'192.168.2.100')
    instance = @class.find(real_instance.uuid)
    instance.put(:reboot)
    pending("check hvc mock server's status")
  end
  
  it "should terminate" do
    real_instance = Instance.create(:status=>0, # offline
                                    :account=>Account[1],
                                    :user=>User[1],
                                    :image_storage=>ImageStorage[1],
                                    :need_cpus=>1,
                                    :need_cpu_mhz=>0.5,
                                    :need_memory=>500,
                                    :hv_agent=>HvAgent[1],
                                    :ip=>'192.168.2.100')
    instance = @class.find(real_instance.uuid)
    instance.put(:terminate)
    pending("check hvc mock server's status")
  end
  
  it "should get describe" do
    real_instance = Instance.create(:status=>0, # offline
                                    :account=>Account[1],
                                    :user=>User[1],
                                    :image_storage=>ImageStorage[1],
                                    :need_cpus=>1,
                                    :need_cpu_mhz=>0.5,
                                    :need_memory=>500,
                                    :hv_agent=>HvAgent[1],
                                    :ip=>'192.168.2.100')
    list = @class.find(:all)
    list.index { |ins| ins.id == real_instance.uuid }.should be_true
  end
  
  it "should snapshot image, and backup image to image storage" do
    pending
    instance = @class.create(:account=>Account[1].id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    
    instance.put(:snapshot)
  end
end

