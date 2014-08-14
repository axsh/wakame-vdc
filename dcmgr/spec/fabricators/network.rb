# -*- coding: utf-8 -*-

Fabricator(:network, class_name: Dcmgr::Models::Network) do
  prefix 24
  network_mode 'securitygroup'
  ipv4_network { sequence { |i| "192.168.#{i}.0" } }
end
