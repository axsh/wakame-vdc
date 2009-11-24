# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/spec_helper'

module Test
  class Instance < ActiveResource::Base
    self.site = 'http://__test__:passwd@localhost:9393/'
    self.format = :json
  end
end

describe "access by active resource" do
  before do
    @user = User.new(:account=>'__test__', :password=>'passwd')
    @user.save
  end

  after do
    @user.delete
  end
  
  it "should run instance" do
    instance = Test::Instance.find($instance.id)
    instance.id.should == $instance.id
  end

  it "should reboot"
  it "should terminate"
  it "should get describe"
  it "should snapshot image, and backup image to image storage"

  it "should get list" do
    list = Test::Instance.find(:all)
    list.index { |ins| ins.id == $instance.id }.should be_true
  end
end

