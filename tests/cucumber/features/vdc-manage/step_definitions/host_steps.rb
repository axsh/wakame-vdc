# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

Given /^(\d+) hosts are created$/ do |amount|
  @host_uuids = []
  (1 .. amount.to_i).each { |i|
    uuid = gen_uuid_body
    @host_uuids << %x{./vdc-manage host add hva.#{uuid} --force --uuid hn-#{uuid}}.chomp
    $?.exitstatus.should == 0
  }
end

Then /^we (should|should\snot) be able to create hosts with the same uuids$/ do |outcome|
  @host_uuids.each { |uuid|
    %x{./vdc-manage host add hva.#{uuid} --force --uuid hn-#{uuid}}.chomp
    check_outcome(outcome)
  }
end

Then /^we (should|should\snot) be able to show the hosts$/ do |outcome|
  @host_uuids.each { |uuid|
    %x{./vdc-manage host show #{uuid}}
    check_outcome(outcome)
  }
end

Then /^we should be able to modify "([^"]*)" as "([^"]*)" for existing hosts$/ do |v, k|
  @host_uuids.each { |uuid|
    %x{./vdc-manage host modify #{uuid} --#{k} #{v}}
    $?.exitstatus.should == 0
  }
end

When /^we delete the hosts$/ do
  @host_uuids.each { |uuid|
    %x{./vdc-manage host del #{uuid}}
    $?.exitstatus.should == 0
  }
end

def gen_uuid_body(length = 10)
  maxlen = 36
  (0..length).map{ rand(maxlen).to_s(maxlen) }.join
end
