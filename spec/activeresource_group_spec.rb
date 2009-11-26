# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/spec_helper'

describe "group access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :Group
  end

  it "should add" do
    group = @class.create(:name=>'group 1')
    group.id.should > 0
    $group = group
  end
  
  it "should delete" do
    id = $group.id
    lambda {
      $group.destroy
    }.should change{ Group[id] }
  end
end

