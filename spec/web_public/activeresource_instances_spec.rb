# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "instance access by active resource" do
  include ActiveResourceHelperMethods
  
  before(:each) do
    reset_db

    @class = ar_class :Instance
    @physical_host_class = ar_class :PhysicalHost
    @name_tag_class = ar_class :NameTag
    @auth_tag_class = ar_class :AuthTag
    @user_class = ar_class :User
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

    #    A B None
    # 1F 0 3 6
    # 2F 1 4 7
    # 3F 2 5
    # Physical Host 2: 1 instance
    # Physical Host 4: 1 instance
    
    PhysicalHost.destroy
    HvController.destroy
    hosts = []; hv_agents = []
    8.times{|i|
      host = PhysicalHost.create(:cpus=>4, :cpu_mhz=>1.0,
                                 :memory=>2000,
                                 :hypervisor_type=>'xen')
      hosts << host
      host.remove_tag(Tag.system_tag(:STANDBY_INSTANCE))

      if i == 0
        hv_controller = HvController.create(:physical_host=>host,
                                            :ip=>'192.168.1.10')
      end

      hv_agent = HvAgent.create(:hv_controller=>hv_controller,
                                :physical_host=>host,
                                :ip=>"192.168.1.#{i + 20}")
      hv_agents << hv_agent
    }

    Instance.create(:status=>0,
                    :account=>Account[1],
                    :user=>User[1],
                    :image_storage=>ImageStorage[1],
                    :need_cpus=>1, :need_cpu_mhz=>0.2,
                    :need_memory=>100,
                    :hv_agent=>hv_agents[2])
    Instance.create(:status=>0,
                    :account=>Account[1],
                    :user=>User[1],
                    :image_storage=>ImageStorage[1],
                    :need_cpus=>1, :need_cpu_mhz=>0.2,
                    :need_memory=>100,
                    :hv_agent=>hv_agents[4])

    hosts[0].create_location_tag('1F.A', Account[1])
    hosts[1].create_location_tag('2F.A', Account[1])
    hosts[2].create_location_tag('3F.A', Account[1])
    hosts[3].create_location_tag('1F.B', Account[1])
    hosts[4].create_location_tag('2F.B', Account[1])
    hosts[5].create_location_tag('3F.B', Account[1])
    hosts[6].create_location_tag('1F._', Account[1])
    hosts[7].create_location_tag('2F._', Account[1])

    PhysicalHost.order(:id).each{|ph|
      print "#{ph.uuid} / agents: #{ph.hv_agents} / instances: #{ph.hv_agents.map{|a| a.instances}.flatten.join(", ")}#\n"
    }
    
    pending
    instance = @class.create(:account=>Account[1].uuid,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.2,
                             :need_memory=>100,
                             :image_storage=>ImageStorage[1].uuid)
    
    PhysicalHost.order(:id).each{|ph|
      print "#{ph.uuid} / agents: #{ph.hv_agents} / instances: #{ph.hv_agents.map{|a| a.instances}.flatten.join(", ")}#\n"
    }
    
    instance.hv_agent.should == hv_agents[6].uuid
    
    assigned_hosts = {}; assigned_hosts.default = 0
    5.times{
      instance = @class.create(:account=>Account[1].uuid,
                               :need_cpus=>1,
                               :need_cpu_mhz=>0.2,
                               :need_memory=>100,
                               :image_storage=>ImageStorage[1].uuid)
      assigned_hosts[Instance[instance.id].physical_host.uuid] += 1
    }

    PhysicalHost.order(:id).each{|ph|
      print "#{ph.uuid} / agents: #{ph.hv_agents} / instances: #{ph.hv_agents.map{|a| a.instances}.flatten.join(", ")}#\n"
    }
    
    # each floor physica assigned_hosts
    assigned_hosts.length.should == 8
  end

  it "should schedule instances, archetype test"
  
  it "should run instance" do
    hvchttp = Dcmgr::HvcHttpMock.new(HvController[:ip=>'192.168.1.10'])
    Dcmgr::hvchttp = hvchttp
    
    pending
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

