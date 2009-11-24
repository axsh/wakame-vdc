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
    instance = @class.new(:user_id=>1234, :physicalhost_id=>10,
                          :imagestorage_id=>100,
                          :hvspec_id=>10)
    instance.save
    instance.id.should > 0
    @first_id = instance.id
  end

  it "should reboot"
  it "should terminate"
  it "should get describe"
  it "should snapshot image, and backup image to image storage"

  it "should get list" do
    list = @class.find(:all)
    list.index { |ins| ins.id == @first_id.id }.should be_true
  end
end

