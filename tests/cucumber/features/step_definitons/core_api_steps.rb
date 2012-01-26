# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

require 'rubygems'
require 'httparty'
#require 'step_helpers'
require File.dirname(__FILE__) + "/step_helpers.rb"

include RetryHelper
include InstanceHelper

Before do
end

After do
end

def initiate_api_call_results
  @api_call_results = {
    "create" => {},
    "update" => {},
    "delete" => {}
  }
end

Given /^(.+) exists in (.+)$/ do |uuid, suffix|
  APITest.get("/#{suffix}/#{uuid}").success?.should be_true
end

When /^we make an api (create|update|delete) call to (.*) with the following options$/ do |call,suffix,options |
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

When /^we start an instance of (.*) and spec (.+) with the created security group and key pair$/ do |image,spec|
  steps %Q{
    When we make an api create call to instances with the following options
      | image_id | instance_spec_id | ssh_key_id                                            | security_groups                                         |
      | #{image} | #{spec}          | #{@api_call_results["create"]["ssh_key_pairs"]["id"]} | #{@api_call_results["create"]["security_groups"]["id"]} |
  }
end

Then /^the created (.+) should reach state (.+) in (\d+) seconds or less$/ do |suffix,state,seconds|
  retry_until(seconds.to_f) do
    APITest.get("/#{suffix}/#{@api_call_results["create"][suffix]["id"]}")["state"] == state
  end
end

Then /^we should be able to ping the started instance in (\d+) seconds or less$/ do |seconds|
  retry_until(seconds.to_f) do
    ping(@api_call_results["create"]["instances"]["id"]).exitstatus == 0
  end
end

Then /^the started instance should start ssh in (\d+) seconds or less$/ do |seconds|
  ipaddr = APITest.get("/instances/#{@api_call_results["create"]["instances"]["id"]}")["vif"].first["ipv4"]["address"]
  retry_until(seconds.to_f) do
    `echo | nc #{ipaddr} 22`
    $?.exitstatus == 0
  end
end

Then /^we should be able to log into the started instance with user (.+) in (\d+) seconds or less$/ do |user, seconds|
  retry_until_loggedin(@api_call_results["create"]["instances"]["id"], user, seconds.to_i)
end

Then /^we should be able to log into the started instance in (\d+) seconds or less$/ do |seconds|
  ipaddr = APITest.get("/instances/#{@api_call_results["create"]["instances"]["id"]}")["vif"].first["ipv4"]["address"]
  retry_until(seconds.to_f) do
    `echo | nc #{ipaddr} 22`
    $?.exitstatus == 0
  end
end

When /^we (attach|detach) the created volume$/ do |operation|
  steps %Q{
    When we make an api update call to volumes/#{@api_call_results["create"]["volumes"]["id"]}/#{operation} with the following options
    | instance_id                                       | volume_id                                       |
    | #{@api_call_results["create"]["instances"]["id"]} | #{@api_call_results["create"]["volumes"]["id"]} |
  }
end

Then /^the (attach|detach) api call (should|should\snot) be successful/ do |operation,outcome|
  steps %Q{
    Then the update call to the volumes/#{@api_call_results["create"]["volumes"]["id"]}/#{operation} api #{outcome} be successful
  }
end

When /^we create a snapshot from the created volume$/ do
  steps %Q{
    When we make an api create call to volume_snapshots with the following options
    | volume_id                                       | destination |
    | #{@api_call_results["create"]["volumes"]["id"]} | local       |
  }
end

When /^we delete the created (.+)$/ do |suffix|
  initiate_api_call_results if @api_call_results.nil?
  @api_call_results["delete"][suffix] = APITest.delete("/#{suffix}/#{@api_call_results["create"][suffix]["id"]}")
  #steps %Q{
    #When we make an api delete call to #{suffix}/#{@api_call_results["create"][suffix]["id"]} with the following options
  #}
end

When /^we create a volume from the created snapshot$/ do
  steps %Q{
    When we make an api create call to volumes with the following options
      | snapshot_id                                                       |
      | #{@api_call_results["create"]["volume_snapshots"]["id"]}          |
  }
end

When /^we (reboot|stop|start) the created instance$/ do |operation|
  @api_call_results["update"] = {} if @api_call_results["update"].nil?
  @api_call_results["update"]["instances"] = APITest.update("/instances/#{@api_call_results["create"]["instances"]["id"]}/#{operation}", [])
  #steps %Q{
    #When we make an api update call to instances/#{@api_call_results["create"]["instances"]["id"]}/#{operation} with the following options
  #}
end
