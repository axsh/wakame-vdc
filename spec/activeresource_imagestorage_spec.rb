# -*- coding: utf-8 -*-

require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/spec_helper'

describe "image storage access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = describe_activeresource_model :ImageStorage
  end

  it "should upload image" do
    image_storage = @class.create(:imagestoragehost_id=>1,
                          :access_id=>2,
                          :storage_url=>'http://hoge')
    image_storage.id.should > 0
    ImageStorage[image_storage.id].should be_valid
    $image_storage_id = image_storage.id
  end
  
  it "should get list" do
    list = @class.find(:all)
    list.index { |obj| obj.id == $image_storage_id }.should be_true
  end
  
  it "should delete image" do
    id = $image_storage_id
    lambda {
      @class.find(id).destroy
    }.should change{ ImageStorage[id] }
  end    
end

