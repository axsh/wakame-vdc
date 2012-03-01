# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

Before do
  @instances_created = []
end

After do
  @instances_created.each { |instance|
    steps %Q{
      When we make an api delete call to instances/#{instance} with no options
        Then the previous api call should be successful  
    }
  }
end

Given /^a new instance with its uuid in <(.+)> and the following options$/ do |reg,options|
  step "we make an api create call to instances with the following options", options

  steps %Q{
    Then the previous api call should be successful
      And from the previous api call take {"id":} and save it to <#{reg}>

    When the created instance has reached the state "running"
  }

  @instances_created << @registry[reg]
end

Given /^a new instance with its uuid in <(.+)>$/ do |reg|
  steps %Q{
    Given a new instance with its uuid in <#{reg}> and the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | ha_enabled | network_scheduler |
      | wmi-lucid6 | is-demo2         | ssh-demo   | sg-demofgr      | false      | vif3type1         |
  }
end

When /^the created instance has reached the state "(.+)"$/ do |state|
  steps %Q{
    When we wait #{TIMEOUT_BASE} seconds
      Then the created instances should reach state #{state} in #{TIMEOUT_CREATE_INSTANCE} seconds or less
  }
end
