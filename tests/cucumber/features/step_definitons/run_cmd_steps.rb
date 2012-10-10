# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

require File.dirname(__FILE__) + "/../../environment.rb"

Before do
end

After do
end

Given /the working directory is (.*)/ do |dir|
  Dir.chdir "#{VDC_ROOT}/#{dir}"
end

When /the following command is run: (.*)/ do |cmds|
  @cmd_output = %x{#{cmds}}.chomp
  @cmd_exit_code = $?
end

Then /the command (should|should\snot) be successful/ do |outcome|
  check_outcome(outcome)
end

Then /the output should be (.*)/ do |output|
  @cmd_output.should == output
end

def check_outcome(outcome)
  case outcome
    when "should"
      $?.exitstatus.should == 0
    when "should not"
      $?.exitstatus.should_not == 0
    else
      raise "Illegal outcome in .feature file: '#{outcome}'. Legal outcomes are 'should' and 'should_not'"
  end
end
