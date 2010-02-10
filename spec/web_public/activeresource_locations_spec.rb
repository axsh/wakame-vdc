# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "locations access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db
    @c = ar_class :Location
  end

  it "should get locations"
end

