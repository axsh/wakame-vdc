# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

require 'rubygems'
require 'httparty'

require File.dirname(__FILE__) + "/step_helpers.rb"

include RetryHelper
include InstanceHelper

Before do
end

After do
end

Then /^we should be able to ping (i-[a-z0-9]{8}) in (\d+) seconds or less$/ do |uuid,seconds|
  retry_until(seconds.to_f) do
    ping(uuid).exitstatus == 0
  end
end

Then /^we should be able to ping on ip (.+) in (\d+) seconds or less$/ do |arg_ip,seconds|
  ipaddr = variable_get_value(arg_ip)

  retry_until(seconds.to_f) do
    ping_on_ip(ipaddr).exitstatus == 0
  end
end

Then /^we should not be able to ping on ip (.+) in (\d+) seconds or less$/ do |arg_ip,seconds|
  ipaddr = variable_get_value(arg_ip)

  sleep(seconds.to_f)
  ping_on_ip(ipaddr).exitstatus.should_not == 0
end

Then /^we should be able to ping instance (.+) through (.+) in (\d+) seconds or less$/ do |arg_instance,arg_network,seconds|
  instance_uuid = variable_get_value(arg_instance)
  network_uuid = variable_get_value(arg_network)

  retry_until(seconds.to_f) do
    ping_on_network(instance_uuid, network_uuid).exitstatus == 0
  end
end

Then /^(i-[a-z0-9]{8}) should start ssh in (\d+) seconds or less$/ do |uuid,seconds|
  ipaddr = APITest.get("/instances/#{uuid}")["vif"].first["ipv4"]["address"]
  retry_until(seconds.to_f) do
    `echo | nc #{ipaddr} 22`
    $?.exitstatus == 0
  end
end

Then /^we should be able to log into (i-[a-z0-9]{8}) with user (.+) in (\d+) seconds or less$/ do |uuid, user, seconds|
  retry_until_loggedin(uuid, user, seconds.to_i)
end

Then /^we should be able to log into (i-[a-z0-9]{8}) in (\d+) seconds or less$/ do |uuid,seconds|
  ipaddr = APITest.get("/instances/#{uuid}")["vif"].first["ipv4"]["address"]
  retry_until(seconds.to_f) do
    `echo | nc #{ipaddr} 22`
    $?.exitstatus == 0
  end
end
