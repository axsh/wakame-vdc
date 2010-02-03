# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::RoleExecutor do
  include Dcmgr::RoleExecutor
  
  it "should evaluate run instance" do
    instance = Instance[1]
    role = Dcmgr::RoleExecutor[instance, :run]
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::RunInstance
    role.evaluate(User[1]).should be_true

    instance.should_receive(:status=)
    instance.should_receive(:save)
    role.execute(User[1]).should be_true
  end

  it "should evaluate shutdown instance" do
    instance = Instance[1]
    role = Dcmgr::RoleExecutor[instance, :shutdown]
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::ShutdownInstance
    role.evaluate(User[1]).should be_true

    instance.should_receive(:status=)
    instance.should_receive(:save)
    role.execute(User[1]).should be_true
  end
  
  it "should evaluate create account" do
    pending
    account = Account.new
    role = Dcmgr::RoleExecutor[account, :create]
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::CreateAccount
    role.evaluate(User[1]).should be_true

    account.should_receive(:save)
    role.execute(User[1]).should be_true
  end
  
  it "should evaluate delete account" do
    pending
    account = Account.create
    role = Dcmgr::RoleExecutor[account, :destroy]
    role.should be_true
    role.class.is_a? Dcmgr::RoleExecutor::DestroyAccount
    role.evaluate(User[1]).should be_true

    account.should_receive(:destroy)
    role.execute(User[1]).should be_true
  end    
  
  it "should evaluate put image storage"
  it "should evaluate get image storage"
  it "should evaluate delete image storage"
  
  it "should evaluate add image storage host"
  it "should evaluate delete image storage host"
  
  it "should evaluate add physical host"
  it "should evaluate delete physical host"
  
  it "should evaluate add hvc"
  it "should evaluate delete hvc"
  
  it "should evaluate add hva"
  it "should evaluate delete hva"
end

