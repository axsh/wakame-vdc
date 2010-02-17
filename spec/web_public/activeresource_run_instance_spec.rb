# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "run instance access by active resource" do
  include ActiveResourceHelperMethods

  it "should run/shutdown instance(sample code)" do
    reset_db

    user_name = "user_a"
    password = "pass"

    # account
    account = ar_class(:Account).create
    account.should be_valid

    # user
    user = ar_class(:User).create(:name=>user_name, :password=>password)
    user.should be_valid
    user.name.should == user_name

    # option for change user
    ar_opts = {:user=>user_name, :password=>password}

    # change user
    user = ar_class(:User, ar_opts).find(:myself)
    p user

    pending
    
    # key pair
    
    # select image

    # auth

    # run instance

    # terminate instance

    # log

    # account log
  end
end

