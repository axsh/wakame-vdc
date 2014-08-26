# -*- coding: utf-8 -*-

Fabricator(:host_node, class_name: Dcmgr::Models::HostNode) do
  offering_cpu_cores 100
  offering_memory_size 102400
  arch 'x86_64'
end
