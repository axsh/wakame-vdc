# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::HvcHttpMock do
  before(:each) do
    
  end

  def get_hvchttp
    hvchttp = Dcmgr::HvcHttpMock.new('192.168.1.10')
    hvchttp.add_hva('192.168.1.20')
    hvchttp.add_instance(:ip=>'192.168.1.21', :status=>:running, :hva=>'192.168.1.20')
    hvchttp.add_instance(:ip=>'192.168.1.22', :status=>:offline, :hva=>'192.168.1.20')
    hvchttp.add_hva('192.168.1.30')
    hvchttp.add_instance(:ip=>'192.168.1.31', :status=>:online, :hva=>'192.168.1.30')
    hvchttp
  end

  it "should load hvc servers, and run instance" do
    Dcmgr::Schema.drop!
    Dcmgr::Schema.create!
    Dcmgr::Schema.load_data File.dirname(__FILE__) + '/../fixtures/sample_data'
    
    hvchttp = Dcmgr::HvcHttpMock.new(HvController[:ip=>'192.168.1.10'])

    hvchttp.hvas.length.should == 3
    hvchttp.hvas.key?('192.168.1.20').should be_true
    hvchttp.hvas.key?('192.168.1.30').should be_true
    hvchttp.hvas.key?('192.168.1.40').should be_true

    hvchttp.hvas['192.168.1.20'].instances.length.should == 1

    instance = Instance[1]

    hvchttp.open('192.168.1.10', 80) {|http|
      res = http.get('/run_instance?hva_ip=%s&instance_uuid=%s&cpus=%s&cpu_mhz=%s&memory=%s' %
                     [instance.hv_agent.ip, instance.uuid, '1', '1.0', '2.0'])
      res.success?.should be_true
      res.body.should == "ok"
    }

    instance.reload
    instance.ip.should be_true

    hvchttp.hvas['192.168.1.20'].instances.length.should == 1
  end

  it "should terminate instance" do
    hvchttp = get_hvchttp
    hvchttp.open('192.168.1.10', 80) {|http|
      res = http.get('/terminate_instance?instance_ip=%s' %
                     ['192.168.1.21'])
      res.success?.should be_true
      res.body.should == "ok"
    }
    hvchttp.hva('192.168.1.20').instances['192.168.1.21'][1].should == :offline
  end
  
  it "should get describe instances" do
    hvchttp = get_hvchttp
    hvchttp.open('192.168.1.10', 80) {|http|
      res = http.get('/describe_instances')
      res.success?.should be_true
      ret = JSON.parse(res.body) # json decode res.body

      ret.key?('192.168.1.20').should be_true
      ret['192.168.1.20'].key?('status').should be_true
      ret['192.168.1.20']['status'].should == 'online'
      ret['192.168.1.20'].key?('instances').should be_true
      
      ret['192.168.1.20']['instances'].key?('192.168.1.21').should be_true
      ret['192.168.1.20']['instances']['192.168.1.21'].key?('status').should be_true
      ret['192.168.1.20']['instances']['192.168.1.21']['status'].should == 'running'
      
      ret['192.168.1.20']['instances']['192.168.1.21'].key?('uuid').should be_true
      
      ret['192.168.1.20']['instances'].key?('192.168.1.22').should be_true
      ret['192.168.1.20']['instances']['192.168.1.22'].key?('status').should be_true
      ret['192.168.1.20']['instances']['192.168.1.22']['status'].should == 'offline'

      ret['192.168.1.20']['instances']['192.168.1.22'].key?('uuid').should be_true
    }
  end

  it "should error access" do
    hvchttp = get_hvchttp
    hvchttp.open('192.168.1.10', 1080) {|http|
      res = http.get('/')
      res.success?.should be_false
      res.status.should == 404
    }
  end
end
