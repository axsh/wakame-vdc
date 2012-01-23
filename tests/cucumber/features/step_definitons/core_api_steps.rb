# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

require 'rubygems'
require 'httparty'

Before do
end

After do
end

When /we make a api create calls to (.*) with the following options/ do |suffix,options|
  @create_results = []
  options.hashes.each { |option_hash|
    @create_results << APITest.create("/#{suffix}",option_hash)
  }
end

Then /the create calls (?:should|should not) be successful/ do |outcome|
  @create_results.each { |result|
    case outcome
      when "should"
        result.success?.should == true
      when "should not"
        result.success?.should == false
      else
        raise "Illegal outcome in .feature file: '#{outcome}'. Legal outcomes are 'should' and 'should_not'"
    end
  }
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
  
  base_uri "http://localhost:9001/api"
  headers 'X-VDC-ACCOUNT-UUID' => 'a-shpoolxx'

  def self.create(path, params)
    self.post(path, :query=>params, :body=>'')
  end

  def self.update(path, params)
    self.put(path, :query=>params, :body=>'')
  end
end
