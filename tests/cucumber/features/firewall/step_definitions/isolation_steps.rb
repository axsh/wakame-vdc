# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

Before do
end

After do |scenario|
end

Given /^an instance ([^\s]+) is started with the following options$/ do |instance_name,options|
  @instances = {} if @instances.nil?
  raise "And instance already exists with that name: '#{instance_name}'" unless @instances[instance_name].nil?
  
  step "we make a successful api create call to instances with the following options", options
  step "the created instance has reached the state \"running\""
  
  @instances[instance_name] = @api_last_result
end

Given /^an instance ([^\s]+) is started in group ([^\s]+)$/ do |instance_name,group_name|
  steps %Q{
    Given an instance #{instance_name} is started with the following options
    | image_id               | instance_spec_id | security_groups                | ssh_key_id |
    | wmi-secgtest           | is-demospec      | <registry:group_#{group_name}> | ssh-demo   |
  }
end

Given /^an instance ([^\s]+) is started in group ([^\s]+) with scheduler ([^\s]+)$/ do |instance_name, group_name, scheduler|
  steps %Q{
    Given an instance #{instance_name} is started with the following options
    | image_id               | instance_spec_id | network_scheduler | security_groups                | ssh_key_id |
    | wmi-secgtest           | is-demo2         | #{scheduler}      | <registry:group_#{group_name}> | ssh-demo   |
  }
end

When /^instance ([^\s]+) pings ip (([^\s]+))$/ do |sender,username, ip|
  @ping_result = {} if @ping_result.nil?
  @ping_result[sender] = {} if @ping_result[sender].nil?
  
  raise "Unknown instance name: #{sender}" if @instances.nil? || @instances[sender].nil?
  if @instances[sender]["vif"].empty?
    steps %Q{
      When we make a successful api get call to #{"instances/#{@instances[sender]["id"]}"} with no options
    }
    @instances[sender] = @api_last_result
  end
  
  @ping_result[sender][ip] = ssh_command(@instances[sender]["id"], "ubuntu", "/opt/ping.rb #{ip} #{TIMEOUT_BASE}", TIMEOUT_BASE).chomp
  @last_sender_name = sender
  @last_pinged_ip = ip
end

When /^instance ([^\s]+) pings instance ([^\s]+)$/ do |sender, receiver|
  # Get the instance's ip addresses if we don't have them yet
  if @instances[receiver]["vif"].empty?
    steps %Q{
      When we make a successful api get call to #{"instances/#{@instances[receiver]["id"]}"} with no options
    }
    @instances[receiver] = @api_last_result
  end

  receiver_address = @instances[receiver]["vif"].first["ipv4"]["address"]
  
  steps %Q{
    When instance #{sender} pings ip #{receiver_address}
  }
  @last_sender = @instances[sender]
  @last_receiver = @instances[receiver]
end

When /^instance ([^\s]+) pings instance ([^\s]+) on each nic$/ do |sender,receiver|
  # Get the instance's ip addresses if we don't have them yet
  if @instances[receiver]["vif"].empty?
    steps %Q{
      When we make a successful api get call to #{"instances/#{@instances[receiver]["id"]}"} with no options
    }
    @instances[receiver] = @api_last_result
  end

  @instances[receiver]["vif"].each { |vnic|
    receiver_address = vnic["ipv4"]["address"]
    receiver_vnic = vnic["vif_id"]
    
    puts "pinging: #{receiver_address}"
    steps %Q{
      When instance #{sender} pings ip #{receiver_address}
    }
  }
  @last_sender_name = sender
  @last_receiver_name = receiver
end

Then /^the ping operation from instance ([^\s]+) to ip ([^\s]+) (should|should\snot) be successful$/ do |sender,ip,outcome|
  raise "Unknown instance name: '#{sender}'" if @ping_result[sender].nil?
  raise "Instance '#{sender}' has not pinged ip '#{ip}' yet" if @ping_result[sender][ip].nil?
  #puts "#{sender} to #{ip}"
  #puts @ping_result[sender][ip]
  case outcome
    when "should"
      puts "pinging #{ip} should work"
      @ping_result[sender][ip].should == "true"
    when "should not"
      puts "pinging #{ip} should not work"
      @ping_result[sender][ip].should_not == "true"
  end
end

Then /^the ping operation (should|should\snot) be successful$/ do |result|
  steps %Q{
    Then the ping operation from instance #{@last_sender_name} to ip #{@last_pinged_ip} #{result} be successful
  }
end

Then /^the ping operation (should|should\snot) be successful for each nic$/ do |result|
  @instances[@last_receiver_name]["vif"].each { |vnic|
    receiver_address = vnic["ipv4"]["address"]
    steps %Q{
      Then the ping operation from instance #{@last_sender_name} to ip #{receiver_address} #{result} be successful
    }
  }
end


