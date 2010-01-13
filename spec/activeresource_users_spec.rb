# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe "user access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :User
    @auth_tag_class = describe_activeresource_model :AuthTag
  end

  it "should add" do
    user = @class.create(:name=>'__test_as_user_spec__', :password=>'passwd')
    user.id.should be_true
    user.id.length.should >= 10
    
    User[user.id].should be_valid
    
    $user = user
  end

  it "should delete" do
    id = $user.id
    $user.destroy
    User[id].should be_nil
  end

  it "should get myself" do
    user = @class.find(:myself)
    user.name.should == $spec_user.name
  end

  it "should add tag" do
    user = @class.find(:myself)
    real_user = User[user.id]
    tag_length = real_user.tags.length
    
    instance_crud_auth_tag = @auth_tag_class.create(:name=>'instance crud',
                                                    :role=>0,
                                                    :tags=>[],
                                                    :account=>@account) # auth tag
    user.put(:add_tag, :tag=>instance_crud_auth_tag)

    real_user = User[user.id]
    real_user.tags.length.should == (tag_length + 1)
    real_user.tags.index {|tag|
      tag.uuid == instance_crud_auth_tag.id
    }.should be_true
  end
  
  it "should notauthorize by bad password" do
    notauth_class = describe_activeresource_model :User, '__test_as_user_spec__', 'badpass'
    lambda {
      notauth_class.create(:name=>'__test_as_user_spec__', :password=>'passwd')
    }.should raise_error
  end

  it "should get default password" do
    pending
    real_user = User[user.id]
    real_user.default_password.should = 'passwd'
  end
end

