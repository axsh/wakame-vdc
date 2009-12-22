# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe "instance access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Instance
    @name_tag_class = describe_activeresource_model :NameTag
    @auth_tag_class = describe_activeresource_model :AuthTag
    @user_class = describe_activeresource_model :User
    @user = @user_class.find(:myself)
    
    @normal_tag_a = @name_tag_class.create(:name=>'tag a', :account=>@account) # name tag
    @normal_tag_b = @name_tag_class.create(:name=>'tag b', :account=>@account)
    @normal_tag_c = @name_tag_class.create(:name=>'tag c', :account=>@account)
    
    instance_crud_auth_tag = @auth_tag_class.create(:name=>'instance crud',
                                                    :roll=>0,
                                                    :tags=>[@normal_tag_a.id,
                                                            @normal_tag_b.id,
                                                            @normal_tag_c.id],
                                                    :account=>@account) # auth tag
    @user.put(:add_tag, :tag=>instance_crud_auth_tag.id)
  end

  it "should run instance" do
    $instance_a = @class.create(:account=>@account)
  end

  it "should shutdown, and auth check" do
    instance = @class.create(:account=>@account)
    instance.should_not be_null

    instance.put(:add_tag, :tag=>@normal_tag_a)
    instance.put(:shutdown)
    
    instance = @class.create(:account=>@account)
    lambda {
     instance.put(:shutdown)
    }.should raise_error(ActiveResource::BadRequest)
  end

  it "should find tag" do
    instance = @class.create(:account=>@account)
    
    instance.tags.include?(@normal_tag_c.id).should be_false
    instance.put(:add_tag, :tag=>@normal_tag_c.id)
    instance.tags.include?(@normal_tag_c.id).should be_true

    instance.put(:remove_tag, :tag=>@normal_tag_c.id)
    instance.tags.include?(@normal_tag_c.id).should be_false
  end

  it "should get instance" do
    instance = @class.find($instance_a.id)
    instance.user_id.should == 1
    instance.physicalhost_id.should == 10
    instance.imagestorage_id.should == 100
    instance.hvspec_id.should == 10
  end

  it "should reboot" do
    instance = @class.find($instance_a.id)
    instance.put(:reboot)
  end
  
  it "should terminate" do
    instance = @class.find($instance_a.id)
    instance.put(:terminate)
  end
  
  it "should get describe" do
    list = @class.find(:all)
    list.each {|o|
      puts "obj %s" % $instance_a.id
      p o
    }
    list.index { |ins| ins.id == $instance_a.id }.should be_true
  end
  
  it "should snapshot image, and backup image to image storage" do
    instance = @class.create(:account=>@account)
    instance.put(:snapshot)
  end
end

