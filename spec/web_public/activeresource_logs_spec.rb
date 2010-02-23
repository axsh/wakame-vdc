# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "log access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db
    @log_c = ar_class :Log
    @accountlog_c = ar_class :AccountLog
  end

  it "should find by month"
  it "should find account log by month" # => response account, instance, status, server type, time(minute)
end

