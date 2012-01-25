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

When /we make an api create call to (.*) with the following options/ do |suffix,options|
  @create_results = {} if @create_results.nil?
  @create_results[suffix] = APITest.create("/#{suffix}",options.hashes.first)
end

Then /the create call to the (.*) api (should|should\snot) be successful/ do |suffix,outcome|
  #@create_results.each { |result|
    case outcome
      when "should"
        @create_results[suffix].success?.should == true
      when "should not"
        @create_results[suffix].success?.should == false
      else
        raise "Illegal outcome in .feature file: '#{outcome}'. Legal outcomes are 'should' and 'should_not'"
    end
  #}
end

When /we start an instance of (.*) with the created security group and key pair/ do |image|
  @create_results = {} if @create_results.nil?
  @create_results["instances"] = APITest.create("/instances",{:image_id=>image,
                                                    #TODO: get rid of this hard coded thing
                                                    :instance_spec_id=>"is-demospec",
                                                    :ssh_key_id=>@create_results["ssh_key_pairs"]["id"],
                                                    :security_groups=>[@create_results["security_groups"]["id"]]})
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


Then /the created (.+) should reach state (.+) in (\d+) seconds or less/ do |suffix,state,seconds|
  retry_until(seconds.to_f) do
    APITest.get("/#{suffix}/#{@create_results[suffix]["id"]}")["state"] == state
  end
end

Then /we should be able to ping the started instance in (\d+) seconds or less/ do |seconds|
  #retry_until_network_started(@create_results["instances"]["id"])
  retry_until(seconds.to_f) do
    ping(@create_results["instances"]["id"]).exitstatus == 0
  end
end

Then /the started instance should start ssh in (\d+) seconds or less/ do |seconds|
  #retry_until_ssh_started(@create_results["instances"]["id"])
  ipaddr = APITest.get("/instances/#{@create_results["instances"]["id"]}")["vif"].first["ipv4"]["address"]
  retry_until(seconds.to_f) do
    `echo | nc #{ipaddr} 22`
    $?.exitstatus == 0
  end
end

Then /we should be able to log into the started instance with user (.+) in (\d+) seconds or less/ do |user, seconds|
  retry_until_loggedin(@create_results["instances"]["id"], user, seconds.to_i)
end

Then /we should be able to log into the started instance in (\d+) seconds or less/ do |seconds|
  #retry_until_ssh_started(@create_results["instances"]["id"])
  ipaddr = APITest.get("/instances/#{@create_results["instances"]["id"]}")["vif"].first["ipv4"]["address"]
  retry_until(seconds.to_f) do
    `echo | nc #{ipaddr} 22`
    $?.exitstatus == 0
  end
end

When /we (attach|detach) the created volume/ do |operation|
  @attach_result = APITest.update("/volumes/#{@create_results["volumes"]["id"]}/#{operation}", {:instance_id=>@create_results["instances"]["id"], :volume_id=>@create_results["volumes"]["id"]})
end

Then /the (attach|detach) api call (should|should\snot) be successful/ do |operation,outcome|
  case outcome
    when "should"
      @attach_result.success?.should == true
    when "should not"
      @attach_result.success?.should == false
    else
      raise "Illegal outcome in .feature file: '#{outcome}'. Legal outcomes are 'should' and 'should_not'"
  end
end

When /we create a snapshot from the created volume/ do
  @create_results["volume_snapshots"] = APITest.create("/volume_snapshots", {:volume_id=>@create_results["volumes"]["id"], :destination=>"local"})
end

When /we delete the created (.+)/ do |suffix|
  @delete_results = {} if @delete_results.nil?
  @delete_results[suffix] = APITest.delete("/#{suffix}/#{@create_results[suffix]["id"]}")
end

Then /Then the delete call to the (.+) api (should|should\snot) be successful/ do |suffix,outcome|
  case outcome
    when "should"
      @delete_results[suffix].success?.should == true
    when "should not"
      @delete_results[suffix].success?.should == false
    else
      raise "Illegal outcome in .feature file: '#{outcome}'. Legal outcomes are 'should' and 'should_not'"
  end
end

Then /Then the update call to the (.+) api (should|should\snot) be successful/ do |suffix,outcome|
  case outcome
    when "should"
      @update_results[suffix].success?.should == true
    when "should not"
      @update_results[suffix].success?.should == false
    else
      raise "Illegal outcome in .feature file: '#{outcome}'. Legal outcomes are 'should' and 'should_not'"
  end
end

When /we create a volume from the created snapshot/ do
  @create_results["volumes"] = APITest.create("/volumes", {:snapshot_id=>@create_results["volume_snapshots"]["id"]})
end

When /we (reboot|stop|start) the created instance/ do |operation|
  @update_results = {} if @update_results.nil?
  @update_results["instances"] = APITest.update("/instances/#{@create_results["instances"]["id"]}/#{operation}", [])
end

