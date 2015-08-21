# -*- coding: utf-8 -*-

Fabricator(:instance, class_name: Dcmgr::Models::Instance) do
  account_id 'a-shpoolxx'
  image { Fabricate(:image) }
  cpu_cores 1
  memory_size 256
end
