require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::RoleExecutor do
  include Dcmgr::RoleExecutor

  before(:all) do
    @user = User[1]
    @account = Account[1]
    @other_account = Account.create
  end
  
  it "should evaluate run instance" do
    instance = Instance[1]
    role = Dcmgr::RoleExecutor.get_role(instance, :run)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::RunInstance
    role.evaluate(@user).should be_true

    instance.should_receive(:status=)
    instance.should_receive(:save)
    role.execute(@user).should be_true
  end

  it "should evaluate shutdown instance" do
    instance = Instance[1]
    role = Dcmgr::RoleExecutor.get_role(instance, :shutdown)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::ShutdownInstance
    role.evaluate(@user).should be_true

    instance.should_receive(:status=)
    instance.should_receive(:save)
    role.execute(@user).should be_true
  end
  
  it "should evaluate create account" do
    account = Account.new
    role = Dcmgr::RoleExecutor.get_role(account, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateAccount
    role.evaluate(@user).should be_true

    account.should_receive(:save)
    role.execute(@user).should be_true
  end
  
  it "should evaluate delete account" do
    account = Account.create
    role = Dcmgr::RoleExecutor.get_role(account, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyAccount
    role.evaluate(@user).should be_true

    account.should_receive(:destroy)
    role.execute(@user).should be_true
  end    
  
  it "should evaluate put image storage" do
    image_storage = ImageStorage.new
    role = Dcmgr::RoleExecutor.get_role(image_storage, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateImageStorage
    role.evaluate(@user).should be_true

    image_storage.should_receive(:save)
    role.execute(@user).should be_true
  end
  
  it "should evaluate get image storage" do
    role = Dcmgr::RoleExecutor.get_role(ImageStorage, :get, :id=>1)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::GetImageStorage
    role.evaluate(@user).should be_true

    role.execute(@user).should == ImageStorage[1]
  end    

  it "should evaluate delete image storage" do
    image_storage = ImageStorage.create
    role = Dcmgr::RoleExecutor.get_role(image_storage, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyImageStorage
    role.evaluate(@user).should be_true

    image_storage.should_receive(:destroy)
    role.execute(@user).should be_true
  end    
  
  it "should evaluate add image storage host" do
    image_storage_host = ImageStorageHost.create
    role = Dcmgr::RoleExecutor.get_role(image_storage_host, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateImageStorageHost
    role.evaluate(@user).should be_true

    image_storage_host.should_receive(:save)
    role.execute(@user).should be_true
  end
  
  it "should evaluate delete image storage host" do
    image_storage_host = ImageStorageHost.create
    role = Dcmgr::RoleExecutor.get_role(image_storage_host, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyImageStorageHost
    role.evaluate(@user).should be_true

    image_storage_host.should_receive(:destroy)
    role.execute(@user).should be_true
  end
  
  it "should evaluate add physical host" do
    physical_host = PhysicalHost.create
    role = Dcmgr::RoleExecutor.get_role(physical_host, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreatePhysicalHost
    role.evaluate(@user).should be_true

    physical_host.should_receive(:save)
    role.execute(@user).should be_true
  end
  
  it "should evaluate delete physical host" do
    physical_host = PhysicalHost.create
    role = Dcmgr::RoleExecutor.get_role(physical_host, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyPhysicalHost
    role.evaluate(@user).should be_true

    physical_host.should_receive(:destroy)
    role.execute(@user).should be_true
  end
  
  it "should evaluate add hvc" do
    hv_controller = HvController.create(:access_url=>'http://localhost/')
    role = Dcmgr::RoleExecutor.get_role(hv_controller, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateHvController
    role.evaluate(@user).should be_true

    hv_controller.should_receive(:save)
    role.execute(@user).should be_true
  end

  it "should evaluate delete hvc" do
    hv_controller = HvController.create(:access_url=>'http://localhost/')
    role = Dcmgr::RoleExecutor.get_role(hv_controller, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyHvController
    role.evaluate(@user).should be_true

    hv_controller.should_receive(:destroy)
    role.execute(@user).should be_true
  end
  
  it "should evaluate add hva" do
    hv_agent = HvAgent.create
    role = Dcmgr::RoleExecutor.get_role(hv_agent, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateHvAgent
    role.evaluate(@user).should be_true

    hv_agent.should_receive(:save)
    role.execute(@user).should be_true
  end

  it "should evaluate delete hva" do
    hv_agent = HvAgent.create
    role = Dcmgr::RoleExecutor.get_role(hv_agent, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyHvAgent
    role.evaluate(@user).should be_true

    hv_agent.should_receive(:destroy)
    role.execute(@user).should be_true
  end
end

