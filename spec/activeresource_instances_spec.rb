# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/spec_helper'

describe "instance access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Instance
  end

  it "should run instance" do
    instance = @class.new(:access_id=>1,
                          :user_id=>1234, :physicalhost_id=>10,
                          :imagestorage_id=>100,
                          :hvspec_id=>10)
    instance.save
    instance.id.should > 0
    $instance_id = instance.id
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

