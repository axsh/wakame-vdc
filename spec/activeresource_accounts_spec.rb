# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe "accounts by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Account
    @user_class = describe_activeresource_model :User
    @user = @user_class.find(:myself)
  end

  it "should add" do
    account = @class.create(:name=>'test account')
    $account = account
    account.id.length.should > 0
    
    real_account = Account.search_by_uuid(account.id)
    real_account.should be_valid
    real_account.uuid.length.should > 0
    real_account.exclusion.should == 'n'
    real_account.enable.should == 'y'

    real_account.account_roll.index{|i| i.user.uuid== @user.id }.should_not be_nil
    
  end
  
  it "should delete" do
    id = $account.id
    $account.destroy
    Account[id].should be_null
  end
end

