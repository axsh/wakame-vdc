# -*- coding: utf-8 -*-
require 'isono'

module DcmgrSpec::Fabricators
  Fabricator(:host_node, class_name: Dcmgr::Models::HostNode) do
    display_name "test hva"
    node_id "hva.test"
    hypervisor "openvz"
    offering_cpu_cores 100
    offering_memory_size 409600
    arch "x86_64"

    after_create do |host, transients|
      Fabricate(:node_state, state: "online", node_id: host.node_id)
    end
  end

  Fabricator(:node_state, class_name: Isono::Models::NodeState)
end
