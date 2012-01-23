# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

require File.dirname(__FILE__) + "/../../../environment"

$:.unshift("#{VDC_ROOT}/dcmgr/lib")
require 'dcmgr'
Dcmgr.configure "#{VDC_ROOT}/dcmgr/config/dcmgr.conf"
Dcmgr.run_initializers('sequel')

include Dcmgr::Models

Before do
end

After do
end


Given /the following records exist in (.*)/ do |model, data|
  m = eval(model)
  data.hashes.each { |row|
    if m[row[:uuid]].nil?
      # The record doesn't exit. Create it.
      row["uuid"] = m.trim_uuid(row[:uuid])
      m.create(row)
    else
      # The record exits. Update it.
      record = m[row[:uuid]]
      row.delete "uuid"
      record.update(row)
    end
  }
end

Given /the following records do not exist in (.*)/ do |model, data|
  m = eval(model)
  data.hashes.each { |row|
    record = m[row[:uuid]]
    record.nil? || record.destroy
  }
end
