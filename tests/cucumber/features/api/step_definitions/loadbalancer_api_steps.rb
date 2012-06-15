# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

When /^the created load_balancer has reached the state "(.+)"$/ do |state|
  #binding.pry
  steps %Q{
    When we wait #{TIMEOUT_BASE} seconds
      Then the created load_balancers should reach state #{state} in #{TIMEOUT_CREATE_INSTANCE} seconds or less
  }
end

