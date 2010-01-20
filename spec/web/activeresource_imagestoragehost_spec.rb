
# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "image storage host access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db
    @class = describe_activeresource_model :ImageStorageHost
  end

  it "should add host" do
    image_storage_host = @class.create
    image_storage_host.id.length.should > 0
    ImageStorageHost[image_storage_host.id].should be_valid
    $image_storage_host_id = image_storage_host.id
  end
  
  it "should delete host" do
    id = $image_storage_host_id
    lambda {
      @class.find(id).destroy
    }.should change{ ImageStorageHost[id] }
  end
end

