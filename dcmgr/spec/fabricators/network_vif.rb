# -*- coding: utf-8 -*-

Fabricator(:network_vif, class_name: Dcmgr::Models::NetworkVif) do
  mac_addr { Fabricate(:mac_lease).mac_addr.to_s(16) }
end
