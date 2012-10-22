# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

Given /^a new volume with its uuid in <(.+)> and the following options$/ do |reg,options|
  step "a managed volume with the following options", options

  steps %Q{
    Then from the previous api call take {"id":} and save it to <#{reg}>
    When the created value has reached the state "available"
  }
end

Given /^a new volume with its uuid in <(.+)>$/ do |reg|
  steps %Q{
    Given a new volume with its uuid in <#{reg}> and the following options
    |volume_size|
    |       1024|
  }
end

When /^the created value has reached the state "(.+)"$/ do |state|
  steps %Q{
    When we wait #{TIMEOUT_BASE} seconds
      Then the created volumes should reach state #{state} in #{TIMEOUT_CREATE_VOLUME} seconds or less
  }
end
