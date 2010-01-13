# -*- coding: utf-8 -*-

require 'dcmgr'

describe Dcmgr::HvcHttpMock do
  before(:each) do
    @hvchttp = Dcmgr::HvcHttpMock.new('192.168.1.10')
    @hvchttp.add_hva('192.168.1.20')
    @hvchttp.add_instance(:ip=>'192.168.1.21', :status=>:runnning, :hva=>'192.168.1.20')
    @hvchttp.add_instance(:ip=>'192.168.1.22', :status=>:offline, :hva=>'192.168.1.20')
    @hvchttp.add_hva('192.168.1.30')
    @hvchttp.add_instance(:ip=>'192.168.1.31', :status=>:online, :hva=>'192.168.1.30')
  end

  it "should run instance" do
    @hvchttp.open('192.168.1.10', 80) {|http|
      res = http.get('/run_instance?hva_ip=%s&cpus=%s&cpu_mhz=%s&memory=%s' %
                     ['192.168.1.20', '1', '1.0', '2.0'])
      res.success?.should be_true
      res.body.should == "ok"
    }

    @hvchttp.hva('192.168.1.20').instances.length.should == 3
  end

  it "should run instance" do
    @hvchttp.open('192.168.1.10', 80) {|http|
      res = http.get('/terminate_instance?instance_ip=%s' %
                     ['192.168.1.21'])
      res.success?.should be_true
      res.body.should == "ok"
    }
    @hvchttp.hva('192.168.1.20').instances['192.168.1.21'].should == :offline
  end
  
  it "should get describe instances" do
    pending
    @hvchttp.open('192.168.1.10', 80) {|http|
      res = http.get('/terminate_instance?instance_ip=%s' %
                     ['192.168.1.22'])
      res.success?.should be_true
      ret = res.body # json decode res.body
      ret.key?('192.168.1.20').should be_true
      ret['192.168.1.20'].key('status').should be_true
    }
  end

  it "should error access" do
    @hvchttp.open('192.168.1.10', 1080) {|http|
      res = http.get('/')
      res.success?.should be_false
      res.status.should == 404
    }
  end
end
