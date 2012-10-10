# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

require 'rubygems'
require 'httparty'

Before do
end

After do
end

When /^we make a successful api (create|update|delete|get|post|put) call to (.*) with no options$/ do |call,suffix |
  steps %{
    When we make an api #{call} call to #{suffix} with no options
    Then the #{call} call to the #{suffix} api should be successful
  }
end

When /^we make a successful api (create|update|delete|get|post|put) call to (.*) with the following options$/ do |call,suffix,options |
  step "we make an api #{call} call to #{suffix} with the following options", options

  step "the #{call} call to the #{suffix} api should be successful"
end

When /^we successfully start an instance of (.*) and (.+) with the new security group and key pair$/ do |image,spec|
  steps %Q{
    Given a new instance with its uuid in <1shot:uuid> and the following options
      | image_id | instance_spec_id | ssh_key_id                                            | security_groups                                         | display_name |
      | #{image} | #{spec}          | #{@api_call_results["create"]["ssh_key_pairs"]["id"]} | #{@api_call_results["create"]["security_groups"]["id"]} | instance1    |
  }
end

When /^we (attach|detach) the created volume$/ do |operation|
  steps %Q{
    When we make a successful api update call to volumes/#{@api_call_results["create"]["volumes"]["id"]}/#{operation} with the following options
    | instance_id                                       | volume_id                                       |
    | #{@api_call_results["create"]["instances"]["id"]} | #{@api_call_results["create"]["volumes"]["id"]} |
  }
end

When /^we successfully (attach|detach) the created volume$/ do |operation|
  steps %Q{
    When we #{operation} the created volume

    Then the update call to the volumes/#{@api_call_results["create"]["volumes"]["id"]}/#{operation} api should be successful
  }
end

When /^we create a snapshot from the created volume$/ do
  steps %Q{
    Given a managed volume_snapshot with the following options
    | volume_id                                       | destination | display_name |
    | #{@api_call_results["create"]["volumes"]["id"]} | local       | snapshot1    |
  }
end

When /^we successfully create a snapshot from the created volume$/ do
  steps %Q{
    When we create a snapshot from the created volume

    Then the create call to the volume_snapshots api should be successful
  }
end

When /^we delete the created (.+)$/ do |suffix|
  steps %Q{
    When we make an api delete call to #{suffix}/#{@api_call_results["create"][suffix]["id"]} with no options

  }
end

When /^we successfully delete the created (.+)$/ do |suffix|
  steps %Q{
    When we delete the created #{suffix}

    Then the delete call to the #{suffix}/#{@api_call_results["create"][suffix]["id"]} api should be successful
  }
end

When /^we create a volume from the created snapshot$/ do
  steps %Q{
    Given a managed volume with the following options
      | snapshot_id                                              |
      | #{@api_call_results["create"]["volume_snapshots"]["id"]} |
  }
end

When /^we successfully create a volume from the created snapshot$/ do
  steps %Q{
    When we create a volume from the created snapshot

    Then the create call to the volumes api should be successful
  }
end

When /^we (reboot|stop|start) the created instance$/ do |operation|
  steps %Q{
    When we make an api update call to instances/#{@api_call_results["create"]["instances"]["id"]}/#{operation} with no options
  }
end

When /^we successfully (reboot|stop|start) the created instance$/ do |operation|
  steps %Q{
    When we #{operation} the created instance

    Then the update call to the instances/#{@api_call_results["create"]["instances"]["id"]}/#{operation} api should be successful
  }
end

Then /^we should be able to ping the started instance in (\d+) seconds or less$/ do |seconds|
  steps %Q{
    Then we should be able to ping #{@api_call_results["create"]["instances"]["id"]} in #{seconds} seconds or less
  }
end

Then /^the started instance should start ssh in (\d+) seconds or less$/ do |seconds|
  steps %Q{
    Then #{@api_call_results["create"]["instances"]["id"]} should start ssh in #{seconds} seconds or less
  }
end

Then /^we should be able to log into the started instance with user (.+) in (\d+) seconds or less$/ do |user, seconds|
  steps %Q{
    Then we should be able to log into #{@api_call_results["create"]["instances"]["id"]} with user #{user} in #{seconds} seconds or less
  }
end
