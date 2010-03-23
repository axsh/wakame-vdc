require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "instance access for scheduling by active resource" do
  include ActiveResourceHelperMethods
  
  before(:each) do
    reset_db

    @c = ar_class :Instance
    @user_class = ar_class :User
    @physical_host_class = ar_class :PhysicalHost
    @name_tag_class = ar_class :NameTag
    @auth_tag_class = ar_class :AuthTag

    Dcmgr::scheduler = Dcmgr::PhysicalHostScheduler::Algorithm2
    
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
    hv_controller_a = HvController.create(:access_url=>'http://192.168.1.10/')

    # hv agents
    HvAgent.destroy
    hv_agent_a = HvAgent.create(:hv_controller=>hv_controller_a,
                                :physical_host=>physical_host_a,
                                :ip=>'192.168.1.20')
    
    @hvchttp = Dcmgr::HvcHttpMock.new
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
    @c = ar_class :Instance
    
    instance = @c.create(:account=>Account[1].uuid,
                         :need_cpus=>3,
                         :need_cpu_mhz=>0.5,
                         :need_memory=>1000,
                         :image_storage=>ImageStorage.first.uuid)
    HvAgent[instance.hv_agent].physical_host == PhysicalHost[1].uuid

    Dcmgr::hvchttp = Dcmgr::HvcHttpMock.new
    
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
    ip_group_count = IpGroup.count
    Instance.each{|instance|
      instance.ip.count == ip_group_count # count by ip groups
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

      hv_controller = HvController.create(:access_url=>'http://192.168.1.10/') if i == 0
      hv_agent = HvAgent.create(:hv_controller=>hv_controller,
                                :physical_host=>host,
                                :ip=>"192.168.1.#{i + 120}")
      hv_agents << hv_agent
    }
    
    hvchttp = Dcmgr::HvcHttpMock.new
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
end

