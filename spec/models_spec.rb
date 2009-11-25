# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/spec_helper'

Wakame::Dcmgr::Schema.models.each{|model|
  describe model do
    before do
      @obj = model.new
    end
    
    it "should be valid" do
      @obj.should be_valid
    end

    it "should not be nil id before save" do
      @obj.id.should be_nil
    end

    it 

    it "shoud be exists table" do
      Wakame::Dcmgr::Schema.table_exists?(model.table_name).should be_true
    end
  end
}
