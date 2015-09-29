# -*- coding: utf-8 -*-

Fabricator(:dc_network, class_name: Dcmgr::Models::DcNetwork) do
  name 'testdc'
  offering_network_modes { ['securitygroup'] }
  allow_new_networks true
end
