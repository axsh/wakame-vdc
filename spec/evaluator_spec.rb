# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::RoleExecutor do
  it "should evaluate run instance"
  it "should evaluate shutdown instance"
  
  it "should evaluate create account"
  it "should evaluate delete account"
  
  it "should evaluate put image storage"
  it "should evaluate get image storage"
  it "should evaluate delete image storage"
  
  it "should evaluate add image storage host"
  it "should evaluate delete image storage host"
  
  it "should evaluate add physical host"
  it "should evaluate delete physical host"
  
  it "should evaluate add hvc"
  it "should evaluate delete hvc"
  
  it "should evaluate add hva"
  it "should evaluate delete hva"
end

