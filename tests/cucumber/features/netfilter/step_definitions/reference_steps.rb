# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

require 'socket'
require 'timeout'

Given /^an instance (.+) is started in group (.+) that listens on (tcp|udp) port (\d+)$/ do |instance_name, group_name, protocol, port|
  steps %Q{
    Given an instance #{instance_name} is started with the following options
    | image_id               | ssh_key_id | user_data           | cpu_cores | service_type | account_id | display_name     | hypervisor  | memory_size | quota_weight | instance_spec_name | vifs                                                                                                         |
    | wmi-secgtest           | ssh-demo   | #{protocol}:#{port} | 1         | std          | a-shpoolxx | #{instance_name} | openvz      | 256         | 1.0          | vz.small           | {\"eth0\":{\"index\":\"1\",\"network\":\"nw-demo1\",\"security_groups\":\"<registry:group_#{group_name}>\"}} |
  }
end

When /^we successfully start an instance (.+) in group (.+) that listens on (tcp|udp) port (\d+)$/ do |instance_name, group_name, protocol, port|
  steps %Q{
    Given an instance #{instance_name} is started with the following options
    | image_id               | instance_spec_id | ssh_key_id | security_groups                | user_data           |
    | wmi-secgtest           | is-demospec      | ssh-demo   | <registry:group_#{group_name}> | #{protocol}:#{port} |
    Then the started instance should start ssh in #{TIMEOUT_CREATE_INSTANCE} seconds or less
  }
end

When /^instance (.+) sends a (tcp|udp) packet to instance (.+) on port (\d+)$/ do |sender_name, protocol, receiver_name, port|
  steps %Q{
    When instance #{sender_name} sends a #{protocol} packet to #{receiver_name}'s inside address on port #{port}
  }
end

Then /^the packet (should|should\snot) arrive successfully$/ do |result|
  if result == "should"
    steps %{Then it should use its inside ip}
  else
    steps %{Then it should fail to send the packet}
  end
end

When /^we update security group (.+) with the following rules$/ do |group_name,rules|
  rules_with_line_breaks = rules.inspect.slice(1,rules.inspect.length-2)
  group_uuid = variable_get_value "<registry:group_#{group_name}>"

  # Fill in the proper uuid if another group is referenced
  parsed_rules = rules_with_line_breaks.gsub(/<Group (.+)>/) { |group|
    grp_name = group.split(" ").last
    variable_get_value "<registry:group_#{grp_name}"
  }

  steps %Q{
    When we make a successful api update call to security_groups/#{group_uuid} with the following options
    | rule                      |
    | #{parsed_rules} |
  }
end
