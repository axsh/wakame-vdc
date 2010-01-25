# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "accounts by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Account
    @user_class = describe_activeresource_model :User
  end
  
  before(:each) do
    reset_db
    @user = @user_class.find(:myself)
  end

  it "should add" do
    account = @class.create(:name=>'test account')
    account.id.length.should > 0
    
    real_account = Account[account.id]
    real_account.should be_valid
    real_account.uuid.length.should > 0
    real_account.enable.should be_true
    real_account.memo.should be_nil
    real_account.contract_at.should be_nil

    real_account.users.find{|user| user.uuid== @user.id }.should be_true
  end

  it "should add with memo, contract_at, enable fields" do
    dt = Time.now
    account = @class.create(:name=>'test account',
                            :enable=>false,
                            :memo=>'memo \n abc',
                            :contract_at=>dt)
    account.id.length.should > 0
    
    real_account = Account[account.id]
    real_account.should be_valid
    real_account.uuid.length.should > 0
    real_account.enable.should be_false
    real_account.memo.should == 'memo \n abc'
    real_account.contract_at.should be_close(dt, 1)

    real_account.users.find{|user| user.uuid== @user.id }.should be_true
  end

  it "should find by id" do
    accounts = @class.find(:all, :params=>{:id=>Account[1].uuid})
    accounts.length.should == 1
    accounts[0].id.should == Account[1].uuid

    accounts = @class.find(:all, :params=>{:id=>'A-1234'})
    accounts.length.should == 0
    
    accounts = @class.find(:all, :params=>{:id=>nil})
    accounts.length.should == 0
    
    accounts = @class.find(:all, :params=>{:id=>''})
    accounts.length.should == 0
  end

  it "should find by account name" do
    accounts = @class.find(:all, :params=>{:name=>Account[1].name})
    accounts.length.should == 1
    accounts[0].id.should == Account[1].uuid
    
    accounts = @class.find(:all, :params=>{:name=>'*account*'})
    accounts.length.should == 2
    accounts[0].id.should == Account[1].uuid
    accounts[1].id.should == Account[2].uuid
    
    accounts = @class.find(:all, :params=>{:name=>'*account*'})
    accounts.length.should == 2
    accounts[0].id.should == Account[1].uuid
    accounts[1].id.should == Account[2].uuid
    
    accounts = @class.find(:all, :params=>{:name=>'*account_hoge*'})
    accounts.length.should == 0
    
    accounts = @class.find(:all, :params=>{:name=>'__test_account_*'})
    accounts.length.should == 1
    accounts[0].id.should == Account[1].uuid
    
    accounts = @class.find(:all, :params=>{:name=>'*_account2__'})
    accounts.length.should == 1
    accounts[0].id.should == Account[2].uuid
    
    accounts = @class.find(:all, :params=>{:name=>'_account2_'})
    accounts.length.should == 0
  end
  
  it "should find by enable, and name" do
    accounts = @class.find(:all, :params=>{:enable=>true, :name=>Account[1].name})
    accounts.length.should == 1
    accounts[0].id.should == Account[1].uuid
    
  end

  it "should find by contract date" do
    accounts = @class.find(:all, :params=>{:contract_at=>[Time.now - 3600, Time.now]})
    accounts.length.should >= 1
    accounts.find{|a| a.id.should == Account[1].uuid}.should be_true
  end    

  it "should get list" do
    list = @class.find(:all)
    list.find{|account| account.id == Account[1].uuid }.should be_true
  end

  it "should get by id" do
    account = @class.find(Account[1].uuid)
    account.id.should == Account[1].uuid
  end

  it "should chagnge" do
    account = @class.create(:name=>'test account')
    
    account.enable.should be_true
    account.enable = false
    account.save
    account.enable.should be_false
    Account[account.id].enable.should be_false

    account.name.should == 'test account'
    account.name = 'changed name'
    account.save
    account.name.should == 'changed name'
    Account[account.id].name.should == 'changed name'
  end

  it "should be able to be used, only enable account"
  
  it "should delete" do
    account = @class.create(:name=>'test account')
    account.destroy
    Account[id].should be_nil
  end

  it "should raise error on duplicate uuid"
end

