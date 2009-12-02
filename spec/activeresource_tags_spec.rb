# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/spec_helper'

describe "tags access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Tag
  end

  it "should add nomal tag" do
    tag = @class.create(:name=>'', :account=>@account)
    tag.id.should > 0

    real_tag = Tag[tag.id]
    real_tag.should be_valid
    real_tag.account.id.should == @account.id
    
    $tag = tag
  end
  
  it "should delete normal tag" do
    id = $tag.id
    $tag.destroy
    Tag[id].should be_null
  end
  
  it "should add auth tag" do
    tag = @class.create(:name=>'instance crud',
                        :auth_type=>'instance', :aut_action=>'crud'
                        :account=>@account)
    tag.id.should > 0

    real_tag = Tag[tag.id]
    real_tag.should be_valid
    real_tag.account.id.should == @account.id
    
    $auth_tag = tag
  end
  
  it "should delete normal tag" do
    $auth_tag.destroy
    Tag[$auth_tag.id].should be_null
  end
end

