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
  cmd = "curl -X PUT -H X_VDC_ACCOUNT_UUID:a-shpoolxx "
  groups.each { |group_id|
    cmd = cmd + "--data-urlencode \"security_groups[]=#{group_id}\" "
  }
  cmd = cmd + "http://localhost:9001/api/12.03/instances/#{inst_id}"
  
  #puts cmd
  system(cmd)
end

Then /^instance ([^\s]+) (should|should\snot) be able to ping instance ([^\s]+)$/ do |pinger, outcome, pingee|
  steps %{
    When instance #{pinger} pings instance #{pingee}
    Then the ping operation #{outcome} be successful
  }
end
