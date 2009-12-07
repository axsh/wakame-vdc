# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
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
    
    User[:uuid=>user.id].should be_valid
    
    $user = user
  end

  it "should authorize" 
  
  it "should delete" do
    id = $user.id
    lambda {
      $user.destroy
    }.should change{ User[id] }
  end
end

