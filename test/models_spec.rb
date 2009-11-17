# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/spec_helper'

Wakame::Dcmgr::Schema.models.each{|model|
  describe model do
    before(:each) do
      @obj = model.new
    end
    
    it "should be valid" do
      @obj.should be_valid
    end
  end
}
