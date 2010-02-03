# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::RoleExecutor do
  include Dcmgr::RoleExecutor

  before(:all) do
    @user = User[1]
    @account = Account[1]
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
    role.class.is_a? Dcmgr::RoleExecutor::GetImageStorageClass
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
  
  it "should evaluate add hvc"
  it "should evaluate delete hvc"
  
  it "should evaluate add hva"
  it "should evaluate delete hva"
end

