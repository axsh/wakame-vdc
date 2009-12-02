# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/spec_helper'

describe "instance access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Instance
    @tag_class = describe_activeresource_model :Tag
  end

  it "should run instance" do
    tag = @tag_class.create(:name=>'instance crud',
                            :auth_type=>'instance', :aut_action=>'crud'
                            :account=>@account)
    
    instance = @class.new(:physicalhost_id=>10,
                          :imagestorage_id=>100,
                          :hvspec_id=>10,
                          :tag=>tag,
                          :account=>@account)
    instance.save
    instance.id.should > 0
    $instance_id = instance.id
  end

  it "should tag" do
    tag = @tag_class[0]
    instance = @class.find($instance_id)
    instance.tags.include?(tag).should be_true

    instance.remove_tag(tag)
    instance.tags.include?(tag).should be_false

    lambda {
      instance.destroy
    }.should error_raise(AuthorizeException)
  end

  it "should get instance" do
    instance = @class.find($instance_id)
    instance.id.should == $instance_id
    instance.access_id.should == "1"
    instance.user_id.should == 1234
    instance.physicalhost_id.should == 10
    instance.imagestorage_id.should == 100
    instance.hvspec_id.should == 10
  end

  it "should reboot" do
    instance = @class.find(1)
    instance.put(:reboot)
  end
  
  it "should terminate" do
    instance = @class.find(1)
    instance.put(:terminate)
  end
  
  it "should get describe" do
    list = @class.find(:all)
    list.index { |ins| ins.id == 1 }.should be_true
  end
  
  it "should snapshot image, and backup image to image storage" do
    instance = @class.find(1)
    instance.put(:snapshot)
  end
end

