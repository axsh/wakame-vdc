# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "keypairs access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db
    @c = ar_class :KeyPair
    @user = ar_class(:User).find(:myself)
  end

  it "should create key pairs" do
    pending

    keypair = @c.create
    keypair.id.should.length > 0
    keypair.secret_body.length.should > 0
    keypair.user.should == @user.id
  end

  it "should delete" do
    pending

    keypair = @c.create

    KeyPair[keypair.id].should be_true

    keypair_id = keypair.id
    keypair.destroy

    KeyPair[keypair.id].should be_nil
  end

  it "should find all" do
    pending
    
    keypair = @c.create

    keypairs = @c.find(:all)
    keypairs.detect{|kp| kp.uuid == keypair.id }.should be_true

    keypair_id = keypair.id
    keypair.destroy

    keypairs = @c.find(:all)
    keypairs.detect{|kp| kp.uuid == keypair.id }.should be_false
  end
end

