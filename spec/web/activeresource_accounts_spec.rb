# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "accounts by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db
    @class = describe_activeresource_model :Account
    @user_class = describe_activeresource_model :User
    @user = @user_class.find(:myself)
  end

  it "should add" do
    account = @class.create(:name=>'test account')
    $account = account
    account.id.length.should > 0
    
    real_account = Account[account.id]
    real_account.should be_valid
    real_account.uuid.length.should > 0
    real_account.enable.should == 'y'
    real_account.memo.should be_nil
    real_account.contract_at.should be_nil

    real_account.users.find{|user| user.uuid== @user.id }.should be_true
  end

  it "should add with memo, contract_at, enable fields" do
    dt = Time.now
    account = @class.create(:name=>'test account',
                            :enable=>'n',
                            :memo=>'memo \n abc',
                            :contract_at=>dt)
    $account = account
    account.id.length.should > 0
    
    real_account = Account[account.id]
    real_account.should be_valid
    real_account.uuid.length.should > 0
    real_account.enable.should == 'n'
    real_account.memo.should == 'memo \n abc'
    real_account.contract_at.should be_close(dt, 1)

    real_account.users.find{|user| user.uuid== @user.id }.should be_true
  end

  it "should find by id" do
    account = @class.find(Account[1].uuid)
    account.id.should == Account[1].uuid
  end

  it "should find by account name"
  
  it "should find by enable"

  it "should find by contract date"

  it "should get list" do
    list = @class.find(:all)
    list.find{|account| account.id == Account[1].uuid }.should be_true
  end

  it "should get by id"

  it "should update by id"

  it "should be able to be used, only enable account"
  
  it "should delete" do
    id = $account.id
    $account.destroy
    Account[id].should be_nil
  end

  it "should raise error on duplicate uuid"
end

