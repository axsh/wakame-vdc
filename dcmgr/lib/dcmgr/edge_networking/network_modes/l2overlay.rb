# -*- coding: utf-8 -*-

module Dcmgr::EdgeNetworking::NetworkModes

  # This network mode provides L2 isolation and anti-spoofing
  # but no user defined security group rules.
  class L2Overlay < SecurityGroup

    def netfilter_secgroup_tasks(secgroup)
      []
    end

  end

end