# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  module FlowGroup

    def active_flows
      @active_flows ||= Array.new
    end

    def queued_flows
      @queued_flows ||= Array.new
    end

    def queue_flow flow
      self.active_flows << flow
      self.queued_flows << flow
    end

    def flush_flows
      use_flows = self.queued_flows
      @queued_flows = Array.new

      self.datapath.add_flows(use_flows)
    end

    def remove_flows
      use_flows = self.active_flows
      @active_flows = Array.new

      self.datapath.del_flows(use_flows)
    end

  end

end
    
