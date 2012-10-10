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
    "get"    => {},
    "post"   => {},
    "put"    => {}
  }
end

def evaluate_argument arg
  return arg unless arg =~ /<[^>]+>/

  result = arg.dup
  while not (registry_id = result[/<([^>]+)>/, 1]).nil?
    @registry.has_key?(registry_id).should be_true
    @registry[registry_id].nil?.should be_false
    result[/<[^>]+>/] = @registry[registry_id]
  end
  result
end

def evaluate_hash_argument arg
  arg.hashes.each { |container|
    container.each { |key,value|
      while not (registry_id = value[/<([^>]+)>/, 1]).nil?
        @registry.has_key?(registry_id).should be_true
        @registry[registry_id].nil?.should be_false
        value[/<[^>]+>/] = @registry[registry_id]
      end
    }
  }
  arg
end

Given /^(.+) exists in (.+)$/ do |uuid, suffix|
  uuid = evaluate_argument(uuid)
  APITest.get("/#{suffix}/#{uuid}").success?.should be_true
end

When /^we make an api (create|update|delete|get|post|put) call to (.+) with no options$/ do |call,arg_suffix|
  suffix = evaluate_argument(arg_suffix)

  initiate_api_call_results if @api_call_results.nil?
  @api_last_request = {:collection=>suffix, :action=>call, :options=>nil }
  @api_last_result = APITest.send_action(call,"/#{suffix}",{})
  @api_call_results[call][suffix] = @api_last_result
  @registry['api:latest'] = @api_last_result.parsed_response
end

When /^we make an api (create|update|delete|get|post|put) call to (.+) with the following options$/ do |call,arg_suffix,arg_options|
  suffix = evaluate_argument(arg_suffix)
  options = evaluate_hash_argument(arg_options)

  initiate_api_call_results if @api_call_results.nil?
  @api_last_request = {:collection=>suffix, :action=>call, :options=>options }
  @api_last_result = APITest.send_action(call,"/#{suffix}",options.hashes.first)
  @api_call_results[call][suffix] = @api_last_result
  @registry['api:latest'] = @api_last_result.parsed_response
end

Then /^the previous api call (should|should\snot) be successful$/ do |outcome|
  @api_last_result.success?.should == (outcome == 'should not' ? false : true)
end

Then /^the previous api call should fail with the HTTP code (\d+)$/ do |rescode|
  @api_last_result.success?.should == false
  @api_last_result.code.to_i.should == rescode.to_i
end

Then /^the previous api call should not make the entry for the uuid (.+)$/ do |uuid|
  uuid = evaluate_argument(uuid)
  res = APITest.get("/#{@api_last_request[:collection]}/#{uuid}")
  res.code.should == 404
end

Then /^the (create|update|delete|get|post|put) call to the (.*) api (should|should\snot) be successful$/ do |call,arg_suffix,outcome|
  suffix = evaluate_argument(arg_suffix)
  @api_call_results[call][suffix].success?.should == (outcome == 'should not' ? false : true)
end

Then /^the created (.+) should reach state (.+) in (\d+) seconds or less$/ do |suffix,state,seconds|
  steps %Q{
    Then the #{suffix} with id #{@api_call_results["create"][suffix]["id"]} should reach state #{state} in #{seconds} seconds or less
  }
end

Then /^the (.+) with id (.+) should reach state (.+) in (\d+) seconds or less$/ do |suffix,uuid,state,seconds|
  uuid = evaluate_argument(uuid)
  state.gsub!("\"", '')
  retry_until(seconds.to_f) do
    APITest.get("/#{suffix}/#{uuid}")["state"] == state
  end
end

When /^we wait (.+) seconds$/ do |seconds|
  sleep(seconds.to_f)
end
