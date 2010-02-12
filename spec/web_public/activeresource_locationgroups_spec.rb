# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "locations access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db
    @c = ar_class :LocationGroup
  end

  it "should get location groups" do
    Dcmgr::location_groups = %w(floor rack power)
    groups = @c.find(:all)
    groups.length.should == 3
    groups[0].name.should == "floor"
    groups[1].name.should == "rack"
    groups[2].name.should == "power"
  end
end

