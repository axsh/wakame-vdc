require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "instance access by active resource" do
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

  it "should create instance" do
    @physical_host_class.find(PhysicalHost.all[0].uuid).put(:remove_tag,
                                                            :tag=>Tag.system_tag(:STANDBY_INSTANCE).uuid)
    instance = @c.create(:account=>Account[1].uuid,
                         :need_cpus=>1, :need_cpu_mhz=>0.5,
                         :need_memory=>1.0,
                         :image_storage=>ImageStorage[1].uuid)
    
    instance.status.should == Instance::STATUS_TYPE_RUNNING
    instance.account.should == Account[1].uuid
    instance.ip.first.should match(/^192\.168\.1\./)

    real_inst = Instance[instance.id]
    real_inst.hv_agent.physical_host_id.should > 0
    real_inst.status.should == Instance::STATUS_TYPE_RUNNING
    real_inst.status_updated_at.should be_close(Time.now, 2)
  end

  it "should run instance" do
    instance_a = @c.create(:account=>Account[1].id,
                           :need_cpus=>1,
                           :need_cpu_mhz=>0.5,
                           :need_memory=>0.5,
                           :image_storage=>ImageStorage[1].uuid)
    
    hvchttp = Dcmgr::HvcHttpMock.new
    Dcmgr::hvchttp = hvchttp
    
    instance_a = @c.find(instance_a.id)
    instance_a.status.should == Instance::STATUS_TYPE_RUNNING
    
    real_inst = Instance[instance_a.id]
    hvchttp.hvas[real_inst.hv_agent.ip].instances[real_inst.ip][1].should == :running
  end
  
  it "should shutdown" do
    instance = @c.create(:account=>Account[1].id,
                         :need_cpus=>1,
                         :need_cpu_mhz=>0.5,
                         :need_memory=>0.5,
                         :image_storage=>ImageStorage[1].uuid)
    instance.should be_true

    hvchttp = Dcmgr::HvcHttpMock.new
    Dcmgr::hvchttp = hvchttp
    
    instance.put(:shutdown)
    
    real_inst = Instance[instance.id]
    hvchttp.hvas[real_inst.hv_agent.ip].
      instances[real_inst.ip][1].should == :offline
  end

  it "should validate and return errors" do
    instance = @c.new(:account=>Account[1].id,
                      :need_cpus=>1,
                      :need_cpu_mhz=>0.5,
                      :need_memory=>0.5)
    instance.save_with_validation.should be_false
    p instance.errors.full_messages
    instance.valid?.should be_false
    instance.errors.should_not be_empty
  end    

  it "should shutdown by sample data, and raise role error" do
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
    tag_c = Tag[:name=>'sample tag c']
    instance = @c.create(:account=>Account[1].id,
                         :need_cpus=>1,
                         :need_cpu_mhz=>0.5,
                         :need_memory=>0.5,
                         :image_storage=>ImageStorage[1])
    instance.tags.include?(tag_c.uuid).should be_false
    instance.put(:add_tag, :tag=>tag_c.uuid)
    
    instance = @c.find(instance.id)
    instance.tags.index{|t| t == tag_c.uuid}.should be_true

    instance.put(:remove_tag, :tag=>tag_c.uuid)
    instance = @c.find(instance.id)
    instance.tags.index{|t| t == tag_c.uuid}.should be_false
  end

  it "should get instance" do
    instance_a = Instance.create(:status=>0, # offline
                                 :account=>Account[1],
                                 :user=>User[1],
                                 :image_storage=>ImageStorage[1],
                                 :need_cpus=>1,
                                 :need_cpu_mhz=>0.5,
                                 :need_memory=>500,
                                 :hv_agent=>HvAgent[1])
    instance = @c.find(instance_a.uuid)
    instance.user.length.should > 0
    instance.image_storage.length.should > 0
  end

  it "should reboot" do
    real_instance = Instance.create(:status=>Instance::STATUS_TYPE_ONLINE,
                                    :account=>Account[1],
                                    :user=>User[1],
                                    :image_storage=>ImageStorage[1],
                                    :need_cpus=>1,
                                    :need_cpu_mhz=>0.5,
                                    :need_memory=>500,
                                    :hv_agent=>HvAgent[1])
    instance = @c.find(real_instance.uuid)

    hvchttp = Dcmgr::HvcHttpMock.new
    Dcmgr::hvchttp = hvchttp

    hvchttp.hvas[real_instance.hv_agent.ip].instances[real_instance.ip][1].should == :online

    instance.put(:reboot)
    
    instance = @c.find(real_instance.uuid)
    instance.status.should == Instance::STATUS_TYPE_ONLINE
    
    hvchttp.hvas[real_instance.hv_agent.ip].instances[real_instance.ip][1].should == :online
  end
  
  it "should terminate" do
    real_instance = Instance.create(:status=>Instance::STATUS_TYPE_ONLINE,
                                    :account=>Account[1],
                                    :user=>User[1],
                                    :image_storage=>ImageStorage[1],
                                    :need_cpus=>1,
                                    :need_cpu_mhz=>0.1,
                                    :need_memory=>100,
                                    :hv_agent=>HvAgent.first)
    instance = @c.find(real_instance.uuid)

    hvchttp = Dcmgr::HvcHttpMock.new
    Dcmgr::hvchttp = hvchttp

    hvchttp.hvas[real_instance.hv_agent.ip].instances[real_instance.ip][1].should == :online
    
    instance.put(:shutdown)
    
    instance = @c.find(real_instance.uuid)
    instance.status.should == Instance::STATUS_TYPE_OFFLINE
    
    hvchttp.hvas[real_instance.hv_agent.ip].instances[real_instance.ip][1].should == :offline
  end
  
  it "should get describe" do
    run_instance = Instance.create(:account=>Account[1],
                                   :user=>User[1],
                                   :image_storage=>ImageStorage[1],
                                   :need_cpus=>1,
                                   :need_cpu_mhz=>0.1,
                                   :need_memory=>100,
                                   :hv_agent=>HvAgent[1])
    run_instance.status = Instance::STATUS_TYPE_RUNNING
    run_instance.save
    
    offline_instance = Instance.create(:account=>Account[1],
                                       :user=>User[1],
                                       :image_storage=>ImageStorage[1],
                                       :need_cpus=>1,
                                       :need_cpu_mhz=>0.1,
                                       :need_memory=>100,
                                       :hv_agent=>HvAgent[1])
    offline_instance.status = Instance::STATUS_TYPE_OFFLINE
    offline_instance.save
    
    old_instance = Instance.create(:account=>Account[1],
                                   :user=>User[1],
                                   :image_storage=>ImageStorage[1],
                                   :need_cpus=>1,
                                   :need_cpu_mhz=>0.1,
                                   :need_memory=>100,
                                   :hv_agent=>HvAgent[1])
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

  it "should get instances by location"
end

