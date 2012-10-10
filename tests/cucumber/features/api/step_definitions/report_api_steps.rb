# encoding: utf-8
require "json_spec/cucumber"
require 'time'

def last_json
  @last_json.to_s
end

World(JsonSpec::Helpers, JsonSpec::Matchers)

Before do
end

After do
  JsonSpec.forget
end

Given "the JSON is:" do |json|
  @json = json
end

When "I get the JSON" do
  @last_json = @json
end

Then /^the previos report api call should be successful with resource_type "([^"]*)"$/ do |resource_type|
  uuid = @managed_resources[resource_type.downcase][0]
  rows = []
  case resource_type
    when "Instance"
      @uuid_match_pattern = 'i-*'
    when "Volume"
      @uuid_match_pattern = 'v-*'
  end

  @resource_type = resource_type
  @api_last_result[0]['results'].collect {|row| rows << row if row['uuid'] == uuid }
  @api_results = rows
end

Then /^the following values exists:$/ do |table|
  uuid = @managed_resources[@resource_type.downcase][0]
  r = ''
  table.hashes.each do |value|
    @api_results.each do |row|
      if row['value'] == value['value']
        @last_json = row.to_json

        steps %Q{
          Then the JSON should be a hash
          Then the JSON response at "uuid" should match "#{@uuid_match_pattern}"
          Then the JSON response at "resource_type" should be "#{@resource_type}"
          Then the JSON response at "event_type" should be "state"
          Then the JSON response at "value" should be "#{value['value']}"
          Then the JSON response at "time" should match format "ISO8601"
        }

      end
    end
  end
end

Then /^the JSON response at "([^"]*)" should match "([^"]*)"$/ do |arg1, arg2|
  last_json = JSON.parse(@last_json)
  last_json[arg1].should match(/#{arg2}/)
end

Then /^the JSON response at "([^"]*)" should match format "([^"]*)"$/ do |arg1, arg2|
  last_json = JSON.parse(@last_json)
  Time.iso8601(last_json[arg1]).class.should == Time
end

