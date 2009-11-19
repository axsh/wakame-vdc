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
  
  it "should not authorize" do
    @user.password = 'hoge'
    @user.save
    lambda {
      instance = Test::Instance.new(:user_id=>1234, :physicalhost_id=>10,
                                    :imagestorage_id=>100,
                                    :hvspec_id=>10)
      instance.save
    }.should raise_error(ActiveResource::UnauthorizedAccess)
    @user.password = 'passwd'
    @user.save
  end
  
  it "should authorize, and save" do
    instance = Test::Instance.new(:user_id=>1234, :physicalhost_id=>10,
                                  :imagestorage_id=>100,
                                  :hvspec_id=>10)
    instance.save
    instance.id.should > 0
    
    $instance = instance
  end

  it "should be update" do
    $instance.user_id = 2
    $instance.save
  end

  it "should be get" do
    instance = Test::Instance.find($instance.id)
    instance.id.should == $instance.id
  end

  it "should be get list" do
    list = Test::Instance.find(:all)
    list.index { |ins| ins.id == $instance.id }.should be_true
  end
end

