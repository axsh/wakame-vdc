#!/usr/bin/env ruby
# encoding: utf-8

require File.dirname(__FILE__) + "/retry.rb"

seconds = ARGV[1].to_f
ipaddr = ARGV[0]

include RetryHelper
begin
  retry_until(seconds) do
    `ping -c 1 -W 1 #{ipaddr}`
    $? == 0
  end
  puts true
  exit 0
rescue
  puts false
  exit(0)
end
