# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe "accounts by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Account
  end

  it "should add" do
    account = @class.create(:name=>'test account')
    account.id.should > 0
    
    real_account = Account[account.id]
    real_account.should be_valid
    
    $account = account
  end
  
  it "should delete" do
    id = $account.id
    $account.destroy
    Account[id].should be_null
  end
end

