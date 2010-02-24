# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::HvcHttpMock do
  include ActiveResourceHelperMethods

  before(:all) do
    reset_db
    @hvchttp = Dcmgr::HvcHttpMock.new
  end

  it "should get hva for hvchttp" do
    hva = HvAgent[:ip=>'192.168.1.20']
    hva_mock = Dcmgr::HvcHttpMock::Hva.new(hva.ip,
                                           hva.instances)
    hva.instances.length.should > 0
    hva_mock.instances.length.should > 0
  end
  
  it "should load hvc servers, and run instance" do
    @hvchttp.hvas.length.should == 3
    @hvchttp.hvas.key?('192.168.1.20').should be_true
    @hvchttp.hvas.key?('192.168.1.30').should be_true
    @hvchttp.hvas.key?('192.168.1.40').should be_true

    @hvchttp.hvas['192.168.1.20'].instances.length.should == 1

    instance = Instance[1]

    @hvchttp.open('192.168.1.10', 80) {|http|
      url = http.run_instance(instance.hv_agent.ip, instance.uuid, instance.ip, instance.mac_address, 1, 1.0, 2.0, :url_only)
      url.should == "/?action=run_instance&hva_ip=#{instance.hv_agent.ip}&instance_uuid=#{instance.uuid}&instance_ip=#{instance.ip}&instance_mac=#{instance.mac_address}&cpus=1&cpu_mhz=1.0&memory=2.0"
      
      res = http.run_instance(instance.hv_agent.ip, instance.uuid, instance.ip, instance.mac_address, 1, 1.0, 2.0)
      res.success?.should be_true
      res.body.should == "ok"
    }

    instance.reload
    instance.ip.should be_true

    @hvchttp.hvas['192.168.1.20'].instances.length.should == 1
  end

  it "should terminate instance" do
    instance = Instance.first
    instance.status = Instance::STATUS_TYPE_RUNNING
    instance.save
    @hvchttp.hva('192.168.1.20').instances.values[0][1].should == :running

    @hvchttp.open('192.168.1.10', 80) {|http|
      url = http.terminate_instance('192.168.1.20', 'I-12345678', :url_only)
      url.should == "/?action=terminate_instance&hva_ip=192.168.1.20&instance_uuid=I-12345678"
      
      res = http.terminate_instance('192.168.1.20', instance.uuid)
      res.success?.should be_true
      res.body.should == "ok"
    }
    @hvchttp.hva('192.168.1.20').instances.values[0][1].should == :offline
  end
  
  it "should get describe instances" do
    @hvchttp.open('192.168.1.10', 80) {|http|
      url = http.describe_instances(:url_only)
      url.should == '/?action=describe_instances'

      res = http.describe_instances
      res.success?.should be_true
      ret = JSON.parse(res.body) # json decode res.body

      ret.key?('192.168.1.20').should be_true
      ret['192.168.1.20'].key?('status').should be_true
      ret['192.168.1.20']['status'].should == 'online'
      ret['192.168.1.20'].key?('instances').should be_true
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
