# -*- coding: utf-8 -*-

Fabricator(:mac_lease, class_name: Dcmgr::Models::MacLease) do
  mac_addr { sequence(:mac_addr, 0x525400000001) }
end
