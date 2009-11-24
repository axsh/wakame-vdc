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

describe "active resource authorization" do
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
  
  it "should authorize" do
    instance = Test::Instance.new(:user_id=>1234, :physicalhost_id=>10,
                                  :imagestorage_id=>100,
                                  :hvspec_id=>10)
    instance.save
    instance.id.should > 0
    
    $instance = instance
  end
end

