# -*- coding: utf-8 -*-

Given /^Network (#{CAPTURE_A_STRING}) has the following dhcp range$/ do |test_name,ranges|
  network = @test_models[test_name]
  raise "#{test_name} is not a Network" unless network.is_a?(Dcmgr::Models::Network)

  range_begin = ranges.hashes[0]["range_begin"]
  range_end = ranges.hashes[0]["range_end"]

  network.add_ipv4_dynamic_range(range_begin,range_end)
end