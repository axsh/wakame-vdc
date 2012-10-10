# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

Given /^(\d+) accounts are created$/ do |amount|
  @acc_uuids = []
  (1..amount.to_i).each { |i|
    @acc_uuids << %x{./gui-manage account add --name cucumber#{i} --description cucumber#{i}}.chomp
    $?.exitstatus.should == 0
  }
end

Then /^we (should|should\snot) be able to create accounts with the same uuids$/ do |outcome|
  @acc_uuids.each { |uuid|
    %x{./gui-manage account add --name cucumber --description cucumber --uuid #{uuid}}
    check_outcome(outcome)
  }
end

Then /^we (should|should\snot) be able to create\/show the accounts oauth keys$/ do |outcome|
  @acc_uuids.each { |uuid|
    %x{./gui-manage account oauth #{uuid}}
    check_outcome(outcome)
  }
end

Then /^we (should|should\snot) be able to associate the accounts with the users$/ do |outcome|
  @acc_uuids.each { |a_uuid|
        %x{./gui-manage account associate #{a_uuid} --users #{@user_uuids.join(" ")}}
        check_outcome(outcome)
  }
end

When /^we delete the accounts$/ do
  @acc_uuids.each { |uuid|
    %x{./gui-manage account del #{uuid}}
  }
end
