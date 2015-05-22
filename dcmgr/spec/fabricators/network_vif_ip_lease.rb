# -*- coding: utf-8 -*-

require 'ipaddress'

Fabricator(:network_vif_ip_lease, class_name: Dcmgr::Models::NetworkVifIpLease) do
  network { Fabricate(:network) }
  ipv4 do |attrs|
    network = attrs[:network]
    range = IPAddress::IPv4.new("#{network.ipv4_network}/#{network.prefix}")

    max = range.max.to_i
    min = range.min.to_i

    rand(min - min) + min
  end
end
