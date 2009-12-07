# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/spec_helper'

Dcmgr::Schema.models.each{|model|
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

    if model.new.is_a? Dcmgr::Model::UUIDMethods
      it "should have uuid" do
        model.prefix_uuid.should be_true
        @obj.uuid.should be_true
      end
    end

    it "shoud be exists table" do
      Dcmgr::Schema.table_exists?(model.table_name).should be_true
    end
  end
}
