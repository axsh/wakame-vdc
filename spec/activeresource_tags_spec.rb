# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/spec_helper'

describe "tags access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Tag
  end

  it "should add name tag" do
    tag = @class.create(:name=>'name tag #1', :account=>@account)
    tag.id.length.should > 0
    tag.tag_type.should == Tag::TYPE_NORMAL

    real_tag = Tag.search_by_uuid(tag.id)
    real_tag.should be_valid
    real_tag.account.id.should == @account.id
    real_tag.tag_type.should == Tag::TYPE_NORMAL
    real_tag.name.should == 'name tag #1'
    
    $tag = tag
  end
  
  it "should delete name tag" do
    id = $tag.id
    $tag.destroy
    Tag.search_by_uuid(id).should be_nil
  end
  
  it "should add auth tag" do
    tag = @class.create(:name=>'instance crud tag #1',
                        :tag_type=>Tag::TYPE_AUTH,
                        :auth_type=>0, :auth_action=>0,
                        :account=>@account)
    tag.id.length.should > 0

    real_tag = Tag.search_by_uuid(tag.id)
    real_tag.should be_valid
    real_tag.account.id.should == @account.id
    real_tag.tag_type.should == Tag::TYPE_AUTH
    real_tag.name.should == 'instance crud tag #1'
    
    $auth_tag = tag
  end
  
  it "should delete auth tag" do
    $auth_tag.destroy
    Tag.search_by_uuid($auth_tag.id).should be_nil
  end
end

