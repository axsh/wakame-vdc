# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

Before do
end

After do |scenario|
end

When /^instance ([^\s]+) is assigned to the following groups$/ do |inst_name, group_options|
  groups = group_options.hashes.map { |grp_hash|
    variable_get_value "<registry:group_#{grp_hash[:group_name]}>"
  }
  
  inst_id = variable_get_value "<#{inst_name}:uuid>"
  
  #step "we make a successful api put call to #{"instances/#{@instances[inst_name]["id"]}"} with the following options", {:security_groups => groups}
  # Just being lazy and using curl for now
  # TODO: Change to a proper api call
  cmd = "curl -s -X PUT -H X_VDC_ACCOUNT_UUID:a-shpoolxx "
  groups.each { |group_id|
    cmd = cmd + "--data-urlencode \"security_groups[]=#{group_id}\" "
  }
  cmd = cmd + "http://localhost:9001/api/12.03/instances/#{inst_id} >> /dev/null"
  
  system(cmd)
end

Then /^instance ([^\s]+) (should|should\snot) be able to ping instance ([^\s]+)$/ do |pinger, outcome, pingee|
  steps %{
    When instance #{pinger} pings instance #{pingee}
    Then the ping operation #{outcome} be successful
  }
end

Given /^security group ([^\s]+) exists with no rules$/ do |group_name|
  steps %{
    Given security group #{group_name} exists with the following rules
      """
      """
  }
end

Given /^an instance ([^\s]+) is started in group ([^\s]+) That listens on (tcp|udp) port (\d+)$/ do |inst_name, group_name, protocol, port|
  steps %{
    Given an instance #{inst_name} is started with the following options
      | image_id     | instance_spec_id | ssh_key_id | cpu_cores | service_type | account_id | display_name | hypervisor  | memory_size | quota_weight | instance_spec_name | user_data           | vifs                                                                                                         |
      | wmi-secgtest | is-demospec      | ssh-demo   | 1         | std          | a-shpoolxx | #{inst_name} | openvz      | 256         | 1.0          | vz.small           | #{protocol}:#{port} | {\"eth0\":{\"index\":\"1\",\"network\":\"nw-demo1\",\"security_groups\":\"<registry:group_#{group_name}>\"}} |
  }
end

Then /^we (should|should\snot) be able to ping instance ([^\s]+)$/ do |outcome, inst_name|
  inst_id = variable_get_value "<#{inst_name}:uuid>"
  
  retry_while_not(TIMEOUT_PACKET_SENDING.to_f) do
    if outcome == "should"
      ping(inst_id).exitstatus != 0
    else
      ping(inst_id).exitstatus == 0
    end
  end
end

Then /^we (should|should\snot) be able to make a (tcp|udp) connection on port (\d+) to instance ([^\s]+)$/ do |outcome, protocol, port, inst_name|
  # Check if we know the instance's ip address yet
  inst_id = variable_get_value "<#{inst_name}:uuid>"
  while @api_call_results["get"]["instances/#{inst_id}"].nil? || @api_call_results["get"]["instances/#{inst_id}"]["vif"].nil?
    steps %Q{
      When we make an api get call to instances/#{inst_id} with no options
      Then the previous api call should be successful
    }
  end
  
  if outcome == "should"
    retry_until(TIMEOUT_PACKET_SENDING.to_f) do
      is_port_open?(@api_call_results["get"]["instances/#{inst_id}"]["vif"].first["ipv4"]["address"],port.to_i,protocol.to_sym)
    end
  else
    retry_while_not(TIMEOUT_PACKET_SENDING.to_f) do
      is_port_open?(@api_call_results["get"]["instances/#{inst_id}"]["vif"].first["ipv4"]["address"],port.to_i,protocol.to_sym)
    end
  end
end
