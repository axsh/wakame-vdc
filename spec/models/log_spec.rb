# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "log" do
  include ActiveResourceHelperMethods

  before(:all) do
    Log.destroy
  end
  
  it "should log user login" do
    @c = ar_class :Instance
    @c.find(Instance[1].uuid)

    log = Log.find(:user_id=>User[1].id, :target_uuid=>User[1].uuid)
    log.should be_true
    log.target_uuid.should == User[1].uuid
    log.action.should == "login"
    log.user.should == User[1]
    log.created_at.should be_close(Time.now, 2)
  end

  it "should log run instance"

  
  it "should log shutdown instance"
end
