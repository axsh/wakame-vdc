# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# describe class:
#   class Instance < ActiveResource::Base
#     self.site = 'http://localhost:port/'
#     self.format = :json
#   end
#
# status:
#   STATUS_TYPE_OFFLINE = 0
#   STATUS_TYPE_RUNNING = 1
#   STATUS_TYPE_ONLINE = 2
#   STATUS_TYPE_TERMINATING = 3
describe "instance access by active resouce(private mode)" do
  include ActiveResourceHelperMethods
  
  before(:all) do
    runserver(:private)
    @c = ar_class :Instance, :private=>true
  end
  
  it "should change instance status" do
    real_instance = Instance[1]
    real_instance.status = Instance::STATUS_TYPE_RUNNING
    real_instance.save
    
    instance = @c.find(Instance[1].uuid)
    instance.status = Instance::STATUS_TYPE_ONLINE
    instance.save

    Instance[1].status.should == Instance::STATUS_TYPE_ONLINE
    @c.find(Instance[1].uuid)
  end
  
  it "should change instance ip address" do
    real_instance = Instance[1]
    real_instance.ip = '192.168.10.1'
    real_instance.save
    
    instance = @c.find(Instance[1].uuid)
    instance.ip = '192.168.11.11'
    instance.save

    real_instance.reload
    real_instance.ip.should == '192.168.11.11'
  end
end
