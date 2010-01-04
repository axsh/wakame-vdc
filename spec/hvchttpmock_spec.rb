# -*- coding: utf-8 -*-

require 'dcmgr'

describe Dcmgr::HvcHttpMock do
  before(:all) do
    @hvchttp = Dcmgr::HvcHttpMock.new
    @hvchttp.add_response('hoge.com', 8080, '/', 200, "ok")
    @hvchttp.add_response('hoge.com', 1080, '/', 500, "ng")
  end

  it "should open" do
    @hvchttp.open('hoge.com', 8080) {|http|
      res = http.get('/')
      res.respond_to?(:success?).should be_true
      res.success?.should be_true
      res.body.should == "ok"
    }
    
    @hvchttp.open('hoge.com', 1080) {|http|
      res = http.get('/')
      res.respond_to?(:success?).should be_true
      res.success?.should be_false
      res.body.should == "ng"
    }
    
    @hvchttp.open('fuga.com', 1080) {|http|
      res = http.get('/')
      res.respond_to?(:success?).should be_true
      res.success?.should be_false
      res.body.should == ""
    }
  end
end
