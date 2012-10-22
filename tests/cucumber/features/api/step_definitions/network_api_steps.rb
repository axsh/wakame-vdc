# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

Given /^a new network with its uuid in <(.+)>$/ do |reg|
  steps %Q{
    Given a managed network with the following options
      |  network |       gw | prefix | description   | network_mode |
      | 10.1.2.0 | 10.1.2.1 |     20 | "test create" | passthru     |
    Then from the previous api call take {"uuid":} and save it to <#{reg}>
  }
end

Given /^a new port in (.+) with its uuid in <(.+)>$/ do |arg_1,reg|
  network = variable_get_value(arg_1)

  # steps %Q{
  #   When we make an api post call to networks/#{network}/ports with no options
  #     Then the previous api call should be successful
  #     And from the previous api call take {"uuid":} and save it to <#{reg}>
  # }

  steps %Q{
    When we make an api post call to networks/#{network}/ports with no options
      Then the previous api call should be successful
      And from the previous api call take {"uuid":} and save it to <#{reg}>
  }
end

Given /^the instance (.+) is connected to the network (.+) with the nic stored in <(.+)>$/ do |arg_1,network,reg|
  instance = variable_get_value(arg_1)

  steps %Q{
    When we make an api get call to instances/#{instance} with no options
      Then the previous api call should be successful
      And from the previous api call take {"vif":[...,,...]} and save it to <#{reg}> for {"network_id":} equal to #{network}
      And from <#{reg}> take {"vif_id":} and save it to <#{reg}uuid>
  }
end

When /^we attach to network (.+) the vif (.+)$/ do |arg_1,arg_2|
  network = variable_get_value(arg_1)
  vif = variable_get_value(arg_2)

  steps %Q{
    When we make an api put call to networks/#{network}/vifs/#{vif}/attach with no options
      Then the previous api call should be successful
  }
end

When /^we detach from network (.+) the vif (.+)$/ do |arg_1,arg_2|
  network = variable_get_value(arg_1)
  vif = variable_get_value(arg_2)

  steps %Q{
    When we make an api put call to networks/#{network}/vifs/#{vif}/detach with no options
      Then the previous api call should be successful
  }
end
