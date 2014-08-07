# -*- coding: utf-8 -*-

#TODO: Investigate invalid mac error that comes up some time

Fabricator(:network_vif, class_name: Dcmgr::Models::NetworkVif) do
  mac_addr { Fabricate(:mac_lease).mac_addr.to_s(16) }
end

Fabricator(:network_vif_with_ip, class_name: Dcmgr::Models::NetworkVif) do
  mac_addr { Fabricate(:mac_lease).mac_addr.to_s(16) }
  ip(count: 1) { Fabricate(:network_vif_ip_lease) }
end
