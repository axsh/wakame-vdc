# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

Before do
end

After do |scenario|
end

Given /^an instance ([^\s]+) is started in group ([^\s]+)$/ do |instance_name,group_name|
  @instances = {} if @instances.nil?
  raise "And instance already exists with that name: '#{instance_name}'" unless @instances[instance_name].nil?
  steps %Q{
    When we make a successful api create call to instances with the following options
    | image_id               | instance_spec_id | security_groups                | ssh_key_id |
    | wmi-secgtest           | is-demospec      | <registry:group_#{group_name}> | ssh-demo   |
    And the created instance has reached the state "running"
  }
  @instances[instance_name] = @api_last_result
end

Given /^an instance ([^\s]+) is started in group ([^\s]+) with scheduler ([^\s]+)$/ do |instance_name, group_name, scheduler|
  @instances = {} if @instances.nil?
  raise "And instance already exists with that name: '#{instance_name}'" unless @instances[instance_name].nil?
  steps %Q{
    When we make a successful api create call to instances with the following options
    | image_id               | instance_spec_id | network_scheduler | security_groups                | ssh_key_id |
    | wmi-secgtest           | is-demo2         | #{scheduler}      | <registry:group_#{group_name}> | ssh-demo   |
    And the created instance has reached the state "running"
  }
  @instances[instance_name] = @api_last_result
end

When /^instance ([^\s]+) pings instance ([^\s]+)$/ do |sender, receiver|
  # Get the instance's ip addresses if we don't have them yet
  [sender,receiver].each { |instance_name|
    if @instances[instance_name]["vif"].empty?
      steps %Q{
        When we make a successful api get call to #{"instances/#{@instances[instance_name]["id"]}"} with no options
      }
      @instances[instance_name] = @api_last_result
    end
  }
  
  #which_address = inout == "inside" ? "address" : "nat_address"
  #sender_address = @instances[sender]["vif"].first["ipv4"]["address"]
  receiver_address = @instances[receiver]["vif"].first["ipv4"]["address"]
  
  seconds = 30
  @ping_result = ssh_command(@instances[sender]["id"], "ubuntu", "/opt/ping.rb #{receiver_address} #{seconds}", seconds+10).chomp
  @last_sender = sender
end

When /^instance ([^\s]+) pings instance ([^\s]+) on each nic$/ do |sender,receiver|
  # Get the instance's ip addresses if we don't have them yet
  [sender,receiver].each { |instance_name|
    if @instances[instance_name]["vif"].empty?
      steps %Q{
        When we make a successful api get call to #{"instances/#{@instances[instance_name]["id"]}"} with no options
      }
      @instances[instance_name] = @api_last_result
    end
  }
  
  #which_address = inout == "inside" ? "address" : "nat_address"
  #sender_address = @instances[sender]["vif"].first["ipv4"]["address"]
  @multi_vnic_ping_result = {} if @multi_vnic_ping_result.nil?
  @instances[receiver]["vif"].each { |vnic|
    receiver_address = vnic["ipv4"]["address"]
    receiver_vnic = vnic["vif_id"]
    
    seconds = 30
    puts "pinging: #{receiver_address}"
    @multi_vnic_ping_result[receiver_vnic] = ssh_command(@instances[sender]["id"], "ubuntu", "/opt/ping.rb #{receiver_address} #{seconds}", seconds+10).chomp
    @last_sender = sender
  }
  @last_receiver = @instances[receiver]
end

Then /^the ping operation (should|should\snot) be successful$/ do |result|
  case result
    when "should"
      @ping_result.should == "true"
    when "should_not"
      @ping_resilt.should_not == "true"
  end
end

Then /^each ping operation (should|should\snot) be successful$/ do |result|
  @last_receiver["vif"].each { |vnic|
    case result
      when "should"
        @multi_vnic_ping_result[vnic["vif_id"]].should == "true"
      when "should_not"
        @multi_vnic_ping_resilt[vnic["vif_id"]].should_not == "true"
    end
  }
end


