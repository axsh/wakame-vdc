# -*- coding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Account do
  it "should raise error on duplicate uuid" do
    lambda {
      Account.create(:name=>"duplicate uuid",
                    :uuid=>Account[1].uuid[2..-1])
    }.should raise_error(Dcmgr::Model::DuplicateUUIDError)
  end
end


