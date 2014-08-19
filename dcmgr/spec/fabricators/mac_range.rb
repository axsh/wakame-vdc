# -*- coding: utf-8 -*-

Fabricator(:mac_range, class_name: Dcmgr::Models::MacRange) do
  vendor_id 0x525400
  range_begin 1
  range_end 0xffffff
end
