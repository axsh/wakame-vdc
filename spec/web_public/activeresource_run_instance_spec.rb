# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "instance access by active resource" do
  include ActiveResourceHelperMethods

  it "should run instance(sample request)" do
    reset_db

    # account
    account = ar_class(:Account).create
    account.should be_valid

    # user
    user = ar_class(:User).create(:name=>"user#1", :password=>"pass")
    user.should be_valid

    pending
    # change user
    
    # key pair

    # select image

    # auth

    # run instance

    # terminate instance

    # log

    # account log
  end
end

