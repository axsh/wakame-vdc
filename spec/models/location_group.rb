# -*- coding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LocationGroup do
  it "should match location_tag_name" do
    LocationGroup.match?("1F.RACK-A", "rack", "RACK-A").should be_true
    LocationGroup.match?("1F.RACK-A", "rack", "RACK-B").should be_false
  end
end
