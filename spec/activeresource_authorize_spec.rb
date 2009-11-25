# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/spec_helper'

describe "active resource authorization" do
  include ActiveResourceHelperMethods
  before(:all) do
    @authuser = User.create(:account=>'__test_auth__', :password=>'passwd',
                            :group_id=>1)
  end

  it "should not authorize" do
    lambda {
      not_auth_instance_class = describe_activeresource_model :Instance, '__test_auth__', 'bad_passwd'
      not_auth_instance_class.create(:access_id=>1,
                                     :user_id=>1234, :physicalhost_id=>10,
                                     :imagestorage_id=>100,
                                     :hvspec_id=>10)
    }.should raise_error(ActiveResource::UnauthorizedAccess)
  end
  
  it "should authorize" do
    auth_instance_class = describe_activeresource_model :Instance, '__test_auth__', 'passwd'
    instance = auth_instance_class.new(:access_id=>1,
                                          :user_id=>1234, :physicalhost_id=>10,
                                          :imagestorage_id=>100,
                                       :hvspec_id=>10)
    instance.save
    instance.id.should > 0
  end
end

