# -*- coding: utf-8 -*-

require 'isono'

module Dcmgr::Rpc
  class NetfilterHandler < EndpointBuilder
    include Dcmgr::VNet::Netfilter::NetfilterAgent

    def initialize(*args)
      super(*args)

      self.verbose_netfilter = Dcmgr.conf.verbose_netfilter
      remove_all_chains
      job = Isono::NodeModules::JobChannel.new(@node)
      job.submit("sg_handler","init_host","hva.#{@node.manifest.node_instance_id}")
    end

    job :apply_netfilter_cmds, proc {
      apply_netfilter_cmds(request.args[0])
    }
  end
end
