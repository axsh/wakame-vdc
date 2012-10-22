# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

Given /^(\d+) users are created$/ do |amount|
  @user_uuids = []
  (1..amount.to_i).each { |i|
    output = %x{./gui-manage user add --name #{random_string} --password #{random_string}}.chomp
    @user_uuids << output[5..15]
    $?.exitstatus.should == 0
  }
end

Then /^we (should|should\snot) be able to show the new users$/ do |outcome|
  @user_uuids.each { |uuid|
    %x{./gui-manage user show #{uuid}}
    check_outcome(outcome)
  }
end

Then /^we (should|should\snot) be able to create users with the same uuids$/ do |outcome|
  @user_uuids.each { |uuid|
    %x{./gui-manage user add --name #{random_string} --password #{random_string} --uuid #{uuid}}
    check_outcome(outcome)
  }
end

Then /^we (should|should\snot) be able to associate the users with the accounts$/ do |outcome|
  @user_uuids.each { |u_uuid|
      @acc_uuids.each { |a_uuid|
        %x{./gui-manage user associate #{u_uuid}  --account-ids #{a_uuid}}
        check_outcome(outcome)
    }
  }
end

When /^we delete the users$/ do
  @user_uuids.each { |uuid|
    %x{./gui-manage user del #{uuid}}
  }
end

def random_string(length = 10)
  (0..length).map{ rand(36).to_s(36) }.join
end
