# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

require 'rubygems'
require 'httparty'
#require 'step_helpers'
#require File.dirname(__FILE__) + "/step_helpers.rb"

#include RetryHelper
#include InstanceHelper

Before do
end

After do
end

def initiate_api_call_results
  @api_call_results = {
    "create" => {},
    "update" => {},
    "delete" => {},
    "get"    => {}
  }
end

Given /^(.+) exists in (.+)$/ do |uuid, suffix|
  APITest.get("/#{suffix}/#{uuid}").success?.should be_true
end

When /^we make an api (create|update|delete|get) call to (.+) with no options$/ do |call,suffix |
  initiate_api_call_results if @api_call_results.nil?
  @api_call_results[call][suffix] = APITest.send(call,"/#{suffix}",{})
end

When /^we make an api (create|update|delete|get) call to (.+) with the following options$/ do |call,suffix,options |
  initiate_api_call_results if @api_call_results.nil?
  @api_call_results[call][suffix] = APITest.send(call,"/#{suffix}",options.hashes.first)
end

Then /^the (create|update|delete) call to the (.*) api (should|should\snot) be successful$/ do |call,suffix,outcome|
  case outcome
    when "should"
      @api_call_results[call][suffix].success?.should == true
    when "should not"
      @api_call_results[call][suffix].success?.should == false
    else
      raise "Illegal outcome in .feature file: '#{outcome}'. Legal outcomes are 'should' and 'should_not'"
  end
end

Then /^the created (.+) should reach state (.+) in (\d+) seconds or less$/ do |suffix,state,seconds|
  retry_until(seconds.to_f) do
    APITest.get("/#{suffix}/#{@api_call_results["create"][suffix]["id"]}")["state"] == state
  end
end
