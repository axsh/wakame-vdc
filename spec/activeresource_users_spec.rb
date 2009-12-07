# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe "user access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :User
  end

  it "should add" do
    user = @class.create(:account=>'__test_as_user_spec__', :password=>'passwd')
    user.id.should be_true
    user.id.length.should >= 10
    
    User.search_by_uuid(user.id).should be_valid
    
    $user = user
  end

  it "should delete" do
    id = $user.id
    $user.destroy
    User.search_by_uuid(id).should be_nil
  end
  
  it "should notauthorize by bad password" do
    notauth_class = describe_activeresource_model :User, '__test_as_user_spec__', 'badpass'
    lambda {
      notauth_class.create(:account=>'__test_as_user_spec__', :password=>'passwd')
    }.should raise_error
  end
end

