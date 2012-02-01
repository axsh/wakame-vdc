# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

Before do
  @networks_created = []
end

After do
  @networks_created.each { |network|
    steps %Q{
      When we make an api delete call to networks/#{network} with no options
        Then the previous api call should be successful
    }
  }
end

Given /^a new network with its uuid in <(.+)>$/ do |reg|
  steps %Q{
    When we make an api create call to networks with the following options
      |  network |       gw | prefix | description   |
      | 10.1.2.0 | 10.1.2.1 |     20 | "test create" |
      Then the previous api call should be successful
      And from the previous api call take {"uuid":} and save it to <#{reg}>
  }

  @networks_created << @registry[reg]
end

Given /^a new port in (.+) with its uuid in <(.+)>$/ do |network, reg|
  steps %Q{
    When we make an api put call to networks/#{network}/add_port with no options
      Then the previous api call should be successful
      And from the previous api call take {"uuid":} and save it to <#{reg}>
  }

  # @networks_created << @registry[reg]
end
