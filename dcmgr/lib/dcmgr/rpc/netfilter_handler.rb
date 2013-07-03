# -*- coding: utf-8 -*-

require 'isono'

module Dcmgr::Rpc
  class NetfilterHandler < EndpointBuilder
    include Dcmgr::Logger
    include Dcmgr::VNet::Netfilter::NetfilterAgent

    def initialize(*args)
      super(*args)

      remove_all_chains
      job = Isono::NodeModules::JobChannel.new(@node)
      job.submit("sg_handler","init_host","hva.#{@node.manifest.node_instance_id}")
    end

    ["init_vnic","destroy_vnic", "init_security_group", "destroy_security_group",
      "init_isolation_group", "destroy_isolation_group", "set_vnic_security_groups",
      "update_sg_rules", "update_isolation_group"].each {|job_name|

      job job_name.to_sym, proc { send(job_name,*request.args) }
    }
  end
end