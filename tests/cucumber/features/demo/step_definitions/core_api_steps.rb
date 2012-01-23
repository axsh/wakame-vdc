# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'
$:.unshift(File.dirname(__FILE__) + '/../../../../spec')
#require 'spec_helper'
#require 'instance.rb'
require 'rubygems'
require 'httparty'

Before do
end

After do
end

When /we make an api show call to (.*)/ do |suffix|
  @api_result = APITest.get("/#{suffix}")
end

WORK_FAIL = {"work" => true, "fail" => false}
Then /the api call should (.*)/ do |outcome| 
  raise "outcome should be one of #{WORK_FAIL.keys.join(",")}" unless WORK_FAIL.keys.member?(outcome)
  @api_result.success?.should == WORK_FAIL[outcome]
end

Then /the result (.*) should be (.*)/ do |key,value|
  @api_result[key].to_s.should == value
end

Then /the result (.*) should not be (.*)/ do |key,value|
  @api_result[key].to_s.should_not == value
end

Then /the results (.*) should not contain (.*)/ do |key,value|
  @api_result.first["results"].find { |result|
    result[key] == value
  }.nil?.should == true
end

Then /the results (.*) should contain (.*)/ do |key,value|
  @api_result.first["results"].find { |result|
    result[key] == value
  }.nil?.should == false
end

######################################
# Helper class
######################################
class APITest
  include HTTParty
  #include Config
  #cfg = Config::ConfigFactory.create_config
  
  base_uri "http://localhost:9001/api"#cfg[:global][:api]
  #format :json
#  headers 'X-VDC-ACCOUNT-UUID' => 'a-00000000'
  headers 'X-VDC-ACCOUNT-UUID' => 'a-shpoolxx'
  #headers 'X-VDC-ACCOUNT-UUID' => cfg[:global][:account]

  def self.create(path, params)
    self.post(path, :query=>params, :body=>'')
  end

  def self.update(path, params)
    self.put(path, :query=>params, :body=>'')
  end
end
