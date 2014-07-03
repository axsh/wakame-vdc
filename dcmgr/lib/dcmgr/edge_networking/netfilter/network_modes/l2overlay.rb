# -*- coding: utf-8 -*-

module Dcmgr::EdgeNetworking::NetworkModes

  # This network mode provides L2 isolation and anti-spoofing
  # but no user defined security group rules.
  class L2Overlay < SecurityGroup

    def set_vnic_security_groups(vnic_id, secg_ids)
      []
    end

  end

end