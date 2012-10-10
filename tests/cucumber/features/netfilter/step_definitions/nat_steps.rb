# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do |scenario|
end

Given /^(inside|outside) network (.+) exists$/ do |inout, cidr|
  new_network = cidr.split("/")[0]
  new_prefix  = cidr.split("/")[1]

  # Check if the network exists already
  steps %Q{
    When we make a successful api get call to networks with no options
  }

  @network = {} if @network.nil?
  @network[inout] = @api_last_result.first["results"].find { |nw|
    nw["prefix"] == new_prefix.to_i && nw["ipv4_network"] == new_network
  }

  # Create the network if it doesn't exist yet
  if @network[inout].nil?
    puts "#{cidr} doesn't exist, creating it"
    steps %Q{
      When we make a successful api create call to networks with the following options
      | network        | prefix        | description                |
      | #{new_network} | #{new_prefix} | nat test #{inout} network  |
    }

    @network[inout] = @api_last_result
  else
    puts "#{cidr} exists, using it"
  end
end

Given /^security group (.+) exists with the following rules$/ do |group_name, rules|
  @security_groups = {} if @security_groups.nil?

  steps %Q{
    When we make a successful api create call to security_groups with the following options
    | description                            |
    | cucumber test group: #{group_name}     |
    Then the previous api call should be successful
    And from the previous api call take {"id":} and save it to <registry:group_#{group_name}>
  }

  # Fill in the proper uuid if another group is referenced
  parsed_rules = rules.gsub(/<Group (.+)>/) { |group|
    grp_name = group.split(" ").last
    variable_get_value "<registry:group_#{grp_name}"
  }

  steps %Q{
    When we successfully set the following rules for the security group
      """
      #{parsed_rules}
      """
  }
end

Given /^a natted instance (.+) is started in group (.+) that listens on tcp port (\d+) and udp port (\d+)$/ do |instance_name, group_name, tcp_port, udp_port|
  @instances = {} if @instances.nil?
  raise "And instance already exists with that name: '#{instance_name}'" unless @instances[instance_name].nil?
  steps %Q{
    Given a new instance with its uuid in <nat_instance:uuid> and the following options
      | image_id               | instance_spec_id | ssh_key_id | network_scheduler | security_groups                | user_data                       |
      | wmi-secgtest           | is-demospec      | ssh-demo   | nat               | <registry:group_#{group_name}> | tcp:#{tcp_port} udp:#{udp_port} |
  }
  @instances[instance_name] = @api_last_result
end

Given /^the security group we use allows pinging and ssh$/ do
  steps %Q{
    When we make a successful api create call to security_groups with the following options
    | description               |
    | static nat test group     |
    When we successfully set the following rules for the security group
      """
      icmp:-1,-1,ip4:0.0.0.0
      tcp:22,22,ip4:0.0.0.0
      """
    Then the previous api call should be successful
  }
end

When /^we successfully terminate instance (.+)$/ do |instance_name|
  steps %Q{
    When we make a successful api delete call to instances/#{@instances[instance_name]["id"]} with no options
    Then the instances with id #{@instances[instance_name]["id"]} should reach state terminated in #{TIMEOUT_TERMINATE_INSTANCE} seconds or less
  }
  @instances[instance_name] = nil
end

When /^we successfully delete security group (.+)$/ do |group_name|
  steps %Q{
    When we make a successful api delete call to security_groups/<registry:group_#{group_name}> with no options
    Then the previous api call should be successful
  }
end

When /^we successfully start instance (.+) of (.+) and (.+) with the (.+) scheduler$/ do |instance_name, image, spec, scheduler|
  steps %Q{
    Given a new instance with its uuid in <nat_instance:uuid> and the following options
    | image_id               | instance_spec_id | ssh_key_id | network_scheduler | security_groups                                         | ssh_key_id |
    | #{image}               | #{spec}          | ssh-demo   | #{scheduler}      | #{@api_call_results["create"]["security_groups"]["id"]} | ssh-demo   |
  }
end

When /^we successfully start instance (.+) that listens on tcp port (\d+) and udp port (\d+) with scheduler (.+)$/ do |instance_name, tcp_port, udp_port, scheduler|
  steps %Q{
    Given an instance #{instance_name} is started with the following options
    | image_id               | instance_spec_id | ssh_key_id | network_scheduler | security_groups                                         | user_data                       |
    | wmi-secgtest           | is-demospec      | ssh-demo   | #{scheduler}      | #{@api_call_results["create"]["security_groups"]["id"]} | tcp:#{tcp_port} udp:#{udp_port} |
  }
end

When /^instance (.+) sends a (tcp|udp) packet to ([^']+)'s (inside|outside) address on port (\d+)$/ do |sender, protocol, receiver, inout, port|
  # Get the instance's ip addresses if we don't have them yet
  [sender,receiver].each { |instance_name|
    if @instances[instance_name]["vif"].empty?
      steps %Q{
        When we make a successful api get call to #{"instances/#{@instances[instance_name]["id"]}"} with no options
      }
      @instances[instance_name] = @api_last_result
    end
  }

  which_address = inout == "inside" ? "address" : "nat_address"
  sender_address = @instances[sender]["vif"].first["ipv4"]["address"]
  receiver_address = @instances[receiver]["vif"].first["ipv4"][which_address]

  begin
    @used_ip = ssh_command(@instances[sender]["id"], "ubuntu", "/opt/tcp.rb #{receiver_address} #{port} #{TIMEOUT_PACKET_SENDING} 2> /dev/null", TIMEOUT_PACKET_SENDING+10).chomp
  rescue RuntimeError => e
    raise unless e.message[0..13] == "Retry Failure:"
    @used_ip = "false"
  end
  @last_sender = sender
end

Then /^instance (.+) should use its (inside|outside) ip$/ do |instance_name, inout|
  which_address = inout == "inside" ? "address" : "nat_address"
  @used_ip.should == @instances[instance_name]["vif"].first["ipv4"][which_address]
end

Then /^it should fail to send the packet$/ do
  @used_ip.should == "false"
end

Then /^it should use its (inside|outside) ip$/ do |inout|
  steps %Q{
    Then instance #{@last_sender} should use its #{inout} ip
  }
end

Then /^we should be able to ping its (inside|outside) ip in (\d+) seconds or less$/ do |inout,seconds|
  # Get the instance's ip addresses if we don't have them yet
  if @api_call_results["get"]["instances/#{@api_call_results["create"]["instances"]["id"]}"].nil?
    steps %Q{
      When we make a successful api get call to #{"instances/#{@api_call_results["create"]["instances"]["id"]}"} with no options
    }
  end

  # Do some pinging
  which_address = inout == "inside" ? "address" : "nat_address"
  ipaddr = @api_call_results["get"]["instances/#{@api_call_results["create"]["instances"]["id"]}"]["vif"].first["ipv4"][which_address]
  retry_until(seconds.to_f) do
    `ping -c 1 -W 1 #{ipaddr}`
    $? == 0
  end
end
