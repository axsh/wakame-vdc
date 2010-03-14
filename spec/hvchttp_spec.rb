# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::HvcHttp do
  include ActiveResourceHelperMethods

  before(:all) do
    reset_db
    @hvchttp = Dcmgr::HvcHttp.new
  end

  after(:all) do
    @hvchttp = Dcmgr::HvcHttpMock.new
  end

  it "should dummy access" do
    @hvchttp.open('localhost', 19393) {|http|
      res = http.get_response({})
      res.should be_nil
    }
  end
end
