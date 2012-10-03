#!/usr/bin/env ruby
# encoding: utf-8

require File.dirname(__FILE__) + "/retry.rb"
require 'socket'
require 'timeout'

seconds = ARGV[2].to_f
ipaddr = ARGV[0]
port = ARGV[1]

include RetryHelper
begin
  retry_until(seconds) do
    begin
      Timeout::timeout(10) do
        s = UDPSocket.new
        s.send("joske", 0, ipaddr, port)
        puts s.recvfrom(1024)[0]
        true
      end
    rescue #Timeout::Error
      false
    end
  end
  exit 0
rescue Errno::ECONNREFUSED
  puts "connection refused"
rescue
  puts false
end

exit(0)
