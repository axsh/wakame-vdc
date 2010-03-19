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
    role = Dcmgr::RoleExecutor.get(instance, :run)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::RunInstance
    role.evaluate(@account, @user).should be_true

    instance.should_receive(:status=)
    instance.should_receive(:save)
    role.execute(@account, @user).should be_true
  end

  it "should evaluate run instance, and check role error by other account" do
    instance = Instance[1]
    role = Dcmgr::RoleExecutor.get(instance, :run)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::RunInstance

    lambda {
      role.evaluate(@other_account, @user).should be_true
    }.should raise_error(Dcmgr::RoleError)

    lambda {
      role.execute(@other_account, @user).should be_true
    }.should raise_error(Dcmgr::RoleError)
  end

  it "should evaluate shutdown instance" do
    instance = Instance[1]
    role = Dcmgr::RoleExecutor.get(instance, :shutdown)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::ShutdownInstance
    role.evaluate(@account, @user).should be_true

    instance.should_receive(:status=)
    instance.should_receive(:save)
    role.execute(@account, @user).should be_true
  end
  
  it "should evaluate create account" do
    account = Account.new
    role = Dcmgr::RoleExecutor.get(account, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateAccount
    role.evaluate(@account, @user).should be_true

    account.should_receive(:save)
    role.execute(@account, @user).should be_true
  end
  
  it "should evaluate delete account" do
    account = Account.create
    role = Dcmgr::RoleExecutor.get(account, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyAccount
    role.evaluate(@account, @user).should be_true

    account.should_receive(:destroy)
    role.execute(@account, @user).should be_true
  end    
  
  it "should evaluate put image storage" do
    image_storage = ImageStorage.new
    role = Dcmgr::RoleExecutor.get(image_storage, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateImageStorage
    role.evaluate(@account, @user).should be_true

    image_storage.should_receive(:save)
    role.execute(@account, @user).should be_true
  end
  
  it "should evaluate get image storage" do
    role = Dcmgr::RoleExecutor.get(ImageStorage, :get, :id=>1)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::GetImageStorage
    role.evaluate(@account, @user).should be_true

    role.execute(@account, @user).should == ImageStorage[1]
  end    

  it "should evaluate delete image storage" do
    image_storage = ImageStorage.create
    role = Dcmgr::RoleExecutor.get(image_storage, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyImageStorage
    role.evaluate(@account, @user).should be_true

    image_storage.should_receive(:destroy)
    role.execute(@account, @user).should be_true
  end    
  
  it "should evaluate add image storage host" do
    image_storage_host = ImageStorageHost.create
    role = Dcmgr::RoleExecutor.get(image_storage_host, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateImageStorageHost
    role.evaluate(@account, @user).should be_true

    image_storage_host.should_receive(:save)
    role.execute(@account, @user).should be_true
  end
  
  it "should evaluate delete image storage host" do
    image_storage_host = ImageStorageHost.create
    role = Dcmgr::RoleExecutor.get(image_storage_host, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyImageStorageHost
    role.evaluate(@account, @user).should be_true

    image_storage_host.should_receive(:destroy)
    role.execute(@account, @user).should be_true
  end
  
  it "should evaluate add physical host" do
    physical_host = PhysicalHost.create
    role = Dcmgr::RoleExecutor.get(physical_host, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreatePhysicalHost
    role.evaluate(@account, @user).should be_true

    physical_host.should_receive(:save)
    role.execute(@account, @user).should be_true
  end
  
  it "should evaluate delete physical host" do
    physical_host = PhysicalHost.create
    role = Dcmgr::RoleExecutor.get(physical_host, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyPhysicalHost
    role.evaluate(@account, @user).should be_true

    physical_host.should_receive(:destroy)
    role.execute(@account, @user).should be_true
  end
  
  it "should evaluate add hvc" do
    hv_controller = HvController.create(:access_url=>'http://localhost/')
    role = Dcmgr::RoleExecutor.get(hv_controller, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateHvController
    role.evaluate(@account, @user).should be_true

    hv_controller.should_receive(:save)
    role.execute(@account, @user).should be_true
  end

  it "should evaluate delete hvc" do
    hv_controller = HvController.create(:access_url=>'http://localhost/')
    role = Dcmgr::RoleExecutor.get(hv_controller, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyHvController
    role.evaluate(@account, @user).should be_true

    hv_controller.should_receive(:destroy)
    role.execute(@account, @user).should be_true
  end
  
  it "should evaluate add hva" do
    hv_agent = HvAgent.create
    role = Dcmgr::RoleExecutor.get(hv_agent, :create)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateHvAgent
    role.evaluate(@account, @user).should be_true

    hv_agent.should_receive(:save)
    role.execute(@account, @user).should be_true
  end

  it "should evaluate delete hva" do
    hv_agent = HvAgent.create
    role = Dcmgr::RoleExecutor.get(hv_agent, :destroy)
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyHvAgent
    role.evaluate(@account, @user).should be_true

    hv_agent.should_receive(:destroy)
    role.execute(@account, @user).should be_true
  end

  it "should evaluate enable assign ip group"
end

