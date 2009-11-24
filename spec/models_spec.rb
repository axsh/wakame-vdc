# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/spec_helper'

Wakame::Dcmgr::Schema.models.each{|model|
  describe model do
    before do
      Wakame::Dcmgr::Schema.create!
      @obj = model.new
    end
    
    it "should be valid" do
      @obj.should be_valid
    end

    it "shoud be exists table" do
      DB.table_exists?(model.table_name).should be_true
    end
  end
}
