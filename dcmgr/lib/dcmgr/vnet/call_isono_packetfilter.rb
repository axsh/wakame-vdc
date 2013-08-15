# -*- coding: utf-8 -*-

# This module's reason for existing is because we had this
# exact same code in both the scheduler and the sg handler
# node modules. This way we only have to write it once.
# If somebody has a better idea, let me know. ~Andreas
module Dcmgr::VNet::CallIsonoPacketfilter
  def job
    @job ||= Isono::NodeModules::JobChannel.new(node)
  end

  def call_packetfilter_service(host_node, cmds)
    raise "host_node type mismatch. Expected: 'HostNode'. Got: '#{host_node.class}'." unless host_node.is_a?(Dcmgr::Models::HostNode)
    job.submit("packetfilter-handle.#{host_node.node_id}", :apply_packetfilter_cmds , cmds)
  end
end
