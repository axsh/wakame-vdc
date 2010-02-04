# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "instance access by active resource" do
  include ActiveResourceHelperMethods
  
  before(:each) do
    reset_db

    Dcmgr::scheduler = Dcmgr::PhysicalHostScheduler::Algorithm2
    
    @c = ar_class :Instance
    @physical_host_class = ar_class :PhysicalHost
    @name_tag_class = ar_class :NameTag
    @auth_tag_class = ar_class :AuthTag
    @user_class = ar_class :User
    @user = @user_class.find(:myself)
    
    image_storage_host = ImageStorageHost.create
    ImageStorage.create(:image_storage_host=>image_storage_host)
    @image_storage = ImageStorage.create(:image_storage_host=>image_storage_host)
    Instance.destroy
    
    # physical host
    PhysicalHost.destroy
    physical_host_a = PhysicalHost.create(:cpus=>4, :cpu_mhz=>1.0,
                                          :memory=>2000,
                                          :hypervisor_type=>'xen')
    PhysicalHost[physical_host_a.id].remove_tag(Tag.system_tag(:STANDBY_INSTANCE))

    # hv controllers
    HvController.destroy
    hv_controller_a = HvController.create(:physical_host=>physical_host_a,
                                        :ip=>'192.168.1.10')

    # hv agents
    HvAgent.destroy
    hv_agent_a = HvAgent.create(:hv_controller=>hv_controller_a,
                                :physical_host=>physical_host_a,
                                :ip=>'192.168.1.20')
    
    @hvchttp = Dcmgr::HvcHttpMock.new(hv_controller_a)
    Dcmgr::hvchttp = @hvchttp
  end

  it "should not schedule instances while no runnning physical hosts" do
    PhysicalHost.each{|host|
      TagMapping.create(:tag_id=>Tag.system_tag(:STANDBY_INSTANCE).id,
                        :target_type=>TagMapping::TYPE_PHYSICAL_HOST,
                        :target_id=>host.id)
    }
                        
    lambda {
      @c.create(:account=>Account[1].uuid,
                    :need_cpus=>1,
                    :need_cpu_mhz=>0.5,
                    :need_memory=>1.0,
                    :image_storage=>ImageStorage[1].uuid)
      
    }.should raise_error(ActiveResource::BadRequest)
  end

  it "should create instance" do
    @physical_host_class.find(PhysicalHost.all[0].uuid).put(:remove_tag,
                                                        :tag=>Tag.system_tag(:STANDBY_INSTANCE).uuid)
    instance = @c.create(:account=>Account[1].uuid,
                         :need_cpus=>1, :need_cpu_mhz=>0.5,
                         :need_memory=>1.0,
                         :image_storage=>ImageStorage[1].uuid)
    
    instance.status.should == Instance::STATUS_TYPE_RUNNING
    instance.account.should == Account[1].uuid
    instance.ip.should match(/^192\.168\.11\.2/)

    real_inst = Instance[instance.id]
    real_inst.hv_agent.physical_host_id.should > 0
    real_inst.status.should == Instance::STATUS_TYPE_RUNNING
    real_inst.status_updated_at.should be_close(Time.now, 2)
  end

  it "should schedule instances by schedule algorithm 2" do
    reset_db
    Instance.destroy
    Dcmgr::scheduler = Dcmgr::PhysicalHostScheduler::Algorithm2
    # physical hosts
    # id / cpus / mhz / memory
    # 1  / 4    / 1.0  / 2.0 
    # 2  / 2    / 1.6  / 1.0 
    # 3  / 1    / 2.0  / 4.0
    
    # already 'instance a' use physical host 1 in should create instance
    
    instance = @c.create(:account=>Account[1].uuid,
                             :need_cpus=>3,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>1000,
                             :image_storage=>ImageStorage.first.uuid)
    HvAgent[instance.hv_agent].physical_host == PhysicalHost[1].uuid

    Dcmgr::hvchttp = Dcmgr::HvcHttpMock.new(HvController[1])
    
    instance = @c.create(:account=>Account[1].uuid,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.7,
                             :need_memory=>2000,
                             :image_storage=>ImageStorage.first.uuid) # skip 2
    HvAgent[instance.hv_agent].physical_host == PhysicalHost[3].uuid
    
    instance = @c.create(:account=>Account[1].uuid,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.8,
                             :need_memory=>400,
                             :image_storage=>ImageStorage.first.uuid)
    HvAgent[instance.hv_agent].physical_host == PhysicalHost[2].uuid
    
    instance = @c.create(:account=>Account[1].uuid,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.8,
                             :need_memory=>400,
                             :image_storage=>ImageStorage.first.uuid)
    HvAgent[instance.hv_agent].physical_host == PhysicalHost[2].uuid

    # check ips
    Instance.each{|instance|
      Instance.filter(:ip => instance.ip).count.should == 1 # only 1 ip
    }
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
    hosts = []; hv_agents = []; hv_controller = nil
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
                                :ip=>"192.168.1.#{i + 120}")
      hv_agents << hv_agent
    }
    
    hvchttp = Dcmgr::HvcHttpMock.new(hv_controller)
    Dcmgr::hvchttp = hvchttp

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

    #PhysicalHost.order(:id).each{|ph|
    #  print "#{ph.uuid} / agents: #{ph.hv_agents} / instances: #{ph.hv_agents.map{|a| a.instances}.flatten.join(", ")}#\n"
    #}
    
    instance = @c.create(:account=>Account[1].uuid,
                         :need_cpus=>1,
                         :need_cpu_mhz=>0.2,
                         :need_memory=>100,
                         :image_storage=>ImageStorage[1].uuid)
    
    #PhysicalHost.order(:id).each{|ph|
    #  print "#{ph.uuid} / agents: #{ph.hv_agents} / instances: #{ph.hv_agents.map{|a| a.instances}.flatten.join(", ")}#\n"
    #}
    
    instance.hv_agent.should == hv_agents[6].uuid
    
    assigned_hosts = {}; assigned_hosts.default = 0
    10.times{
      instance = @c.create(:account=>Account[1].uuid,
                               :need_cpus=>1,
                               :need_cpu_mhz=>0.2,
                               :need_memory=>100,
                               :image_storage=>ImageStorage[1].uuid)
      assigned_hosts[Instance[instance.id].physical_host.uuid] += 1
      
      #PhysicalHost.order(:id).each{|ph|
      #  print "#{ph.uuid} / agents: #{ph.hv_agents} / instances: #{ph.hv_agents.map{|a| a.instances}.flatten.join(", ")}#\n"
      #}
    }
    
    # each floor physica assigned_hosts
    assigned_hosts.length.should == 8
  end

  it "should schedule instances, archetype test"
  
  it "should run instance" do
    instance_a = @c.create(:account=>Account[1].id,
                               :need_cpus=>1,
                               :need_cpu_mhz=>0.5,
                               :need_memory=>0.5,
                               :image_storage=>ImageStorage[1].uuid)
    
    hvchttp = Dcmgr::HvcHttpMock.new(HvController[:ip=>'192.168.1.10'])
    Dcmgr::hvchttp = hvchttp
    
    instance_a = @c.find(instance_a.id)
    instance_a.status.should == Instance::STATUS_TYPE_RUNNING
    
    real_inst = Instance[instance_a.id]
    hvchttp.hvas[real_inst.hv_agent.ip].instances[real_inst.ip][1].should == :running
  end
  
  it "should shutdown, and auth check"

  it "should shutdown" do
    instance = @c.create(:account=>Account[1].id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5,
                             :image_storage=>ImageStorage[1].uuid)

    real_instance = Instance[instance.id]
    real_instance.ip = '192.168.11.22'
    real_instance.save
    
    instance.should be_true

    hvchttp = Dcmgr::HvcHttpMock.new(HvController[:ip=>'192.168.1.10'])
    Dcmgr::hvchttp = hvchttp
    
    instance.put(:shutdown)
    
    real_inst = Instance[instance.id]
    hvchttp.hvas[real_inst.hv_agent.ip].instances[real_inst.ip][1].should == :offline
  end

  it "should shutdown by sample data, and raise role error" do
    pending
    instance = @c.create(:account=>Account[1].id,
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
    instance = @c.create(:account=>Account[1].id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    
    instance.tags.include?(@normal_tag_c.id).should be_false
    instance.put(:add_tag, :tag=>@normal_tag_c.id)

    instance = @c.find(instance.id)
    instance.tags.include?(@normal_tag_c.id).should be_true

    instance.put(:remove_tag, :tag=>@normal_tag_c.id)
    instance = @c.find(instance.id)
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
    instance = @c.find(instance_a.uuid)
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
    instance = @c.find(real_instance.uuid)
    instance.put(:reboot)
    pending("check hvc mock server's status")
  end
  
  it "should terminate" do
    real_instance = Instance.create(:status=>0, # offline
                                    :account=>Account[1],
                                    :user=>User[1],
                                    :image_storage=>ImageStorage[1],
                                    :need_cpus=>1,
                                    :need_cpu_mhz=>0.1,
                                    :need_memory=>100,
                                    :hv_agent=>HvAgent[1],
                                    :ip=>'192.168.2.100')
    instance = @c.find(real_instance.uuid)
    instance.put(:terminate)
    pending("check hvc mock server's status")
  end
  
  it "should get describe" do
    run_instance = Instance.create(:account=>Account[1],
                                   :user=>User[1],
                                   :image_storage=>ImageStorage[1],
                                   :need_cpus=>1,
                                   :need_cpu_mhz=>0.1,
                                   :need_memory=>100,
                                   :hv_agent=>HvAgent[1],
                                   :ip=>'192.168.2.100')
    run_instance.status = Instance::STATUS_TYPE_RUNNING
    run_instance.save
    
    offline_instance = Instance.create(:account=>Account[1],
                                       :user=>User[1],
                                       :image_storage=>ImageStorage[1],
                                       :need_cpus=>1,
                                       :need_cpu_mhz=>0.1,
                                       :need_memory=>100,
                                       :hv_agent=>HvAgent[1],
                                       :ip=>'192.168.2.100')
    offline_instance.status = Instance::STATUS_TYPE_OFFLINE
    offline_instance.save
    
    old_instance = Instance.create(:account=>Account[1],
                                   :user=>User[1],
                                   :image_storage=>ImageStorage[1],
                                   :need_cpus=>1,
                                   :need_cpu_mhz=>0.1,
                                   :need_memory=>100,
                                   :hv_agent=>HvAgent[1],
                                   :ip=>'192.168.2.100')
    old_instance.status = Instance::STATUS_TYPE_OFFLINE
    old_instance.status_updated_at = Time.now - 86400
    old_instance.save

    list = @c.find(:all)
    list.index {|i| i.id == run_instance.uuid }.should be_true
    list.index {|i| i.id == offline_instance.uuid }.should be_true
    list.index {|i| i.id == old_instance.uuid }.should_not be_true
  end
  
  it "should snapshot image, and backup image to image storage" do
    pending
    instance = @c.create(:account=>Account[1].id,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>0.5)
    
    instance.put(:snapshot)
  end
end

