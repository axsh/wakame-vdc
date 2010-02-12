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
    group.length.should == 3
    group[0].name.should == "floor"
    group[1].name.should == "rack"
    group[2].name.should == "power"
  end
end

