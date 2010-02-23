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
    user.name.should == user_name
    lambda {
      user.password
    }.should raise_error(NoMethodError)

    # mapping account
    user.put(:add_account, :account=>account)

    # key pair
    keypair = ar_class(:KeyPair, ar_opts).create
    keypair.private_key.length.should > 0
    keypair.public_key.length.should > 0
    
    # select image
    images = ar_class(:ImageStorage, ar_opts).find(:all)
    images.length.should > 0
    select_image = images[0]

    # run instance
    instance_c = ar_class(:Instance, ar_opts)
    instance = instance_c.create(:account=>account.id,
                                 :need_cpus=>1, :need_cpu_mhz=>0.5,
                                 :need_memory=>1.0,
                                 :image_storage=>select_image.id,
                                 :keyparir=>keypair.id)
    instance.should be_valid

    # terminate instance
    instance.put(:shutdown)
    
    # log
    

    # account log
  end
end

