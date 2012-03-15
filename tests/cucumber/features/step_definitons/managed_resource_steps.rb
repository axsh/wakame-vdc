# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

Before do
  @managed_resources = {}
end

After do |scenario|
  @managed_resources.each { |key,resources|
    resources.each { |id| step "we make an api delete call to #{key}s/#{id} with no options" }
  }
end

managed_resource_types = '(instance|security_group|volume|ssh_key_pair|network|host_node|storage_node|image|instance_spec|volume_snapshot)'

Given /^a managed #{managed_resource_types} with no options$/ do |type|
  step "we make an api create call to #{type}s with no options"
  step "the previous api call should be successful"

  @managed_resources[type] = [] unless @managed_resources.has_key?(type)
  @managed_resources[type] << @registry['api:latest']['id']
end

Given /^a managed #{managed_resource_types} with the following options$/ do |type,options|
  step "we make an api create call to #{type}s with the following options", options
  step "the previous api call should be successful"

  @managed_resources[type] = [] unless @managed_resources.has_key?(type)
  @managed_resources[type] << @registry['api:latest']['id']
end
