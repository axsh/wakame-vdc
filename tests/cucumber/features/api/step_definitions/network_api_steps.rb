# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

Before do
end

After do
end

Given /^a new network with its uuid in registry (.+)$/ do |registry|
  steps %Q{
    When we make an api create call to networks with the following options
      |  network |       gw | prefix | description   |
      | 10.1.2.0 | 10.1.2.1 |     20 | "test create" |
    Then the previous api call should be successful
    And from the previous api call save to registry #{registry} the value for key uuid
  }
end
