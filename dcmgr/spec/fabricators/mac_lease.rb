# -*- coding: utf-8 -*-

Fabricator(:mac_lease, class_name: Dcmgr::Models::MacLease) do
  mac_addr { rand(0xffffffffffff) }
end
