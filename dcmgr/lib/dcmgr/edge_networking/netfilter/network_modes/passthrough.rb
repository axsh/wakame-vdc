# -*- coding: utf-8 -*-

module Dcmgr::EdgeNetworking::NetworkModes

  # This service type is for networks without firewalls.
  # Therefore there is an empty array returned for all netfilter
  # rule factory methods.
  class PassThrough
    def init_vnic(vnic_map)
      []
    end

    def destroy_vnic(vnic_map)
      []
    end

    def set_vnic_security_groups(vnic_id, secg_ids)
      []
    end
  end

end