# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

Given /^a new instance with its uuid in <(.+)> and the following options$/ do |reg,options|
  step "a managed instance with the following options", options

  steps %Q{
    Then from the previous api call take {"id":} and save it to <#{reg}>
    When the created instance has reached the state "running"
  }
end

Given /^a new instance with its uuid in <(.+)>$/ do |reg|
  steps %Q{
    Given a new instance with its uuid in <#{reg}> and the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | ha_enabled |
      | wmi-lucid6 | is-demo2         | ssh-demo   | sg-demofgr      | false      |
  }
end

Given /^a new instance with its uuid in <(.+)> and network scheduler (.+)$/ do |reg,arg_scheduler|
  scheduler = variable_get_value(arg_scheduler)

  steps %Q{
    Given a new instance with its uuid in <#{reg}> and the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | ha_enabled | network_scheduler |
      | wmi-lucid6 | is-demo2         | ssh-demo   | sg-demofgr      | false      | #{scheduler}      |
  }
end

When /^the created instance has reached the state "(.+)"$/ do |state|
  steps %Q{
    When we wait #{TIMEOUT_BASE} seconds
      Then the created instances should reach state #{state} in #{TIMEOUT_CREATE_INSTANCE} seconds or less
  }
end
