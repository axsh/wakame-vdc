# -*- coding: utf-8 -*-

module Dcmgr::EdgeNetworking::NetworkModes

  # This service type is for networks without firewalls.
  # Therefore there is an empty array returned for all netfilter
  # rule factory methods.
  class PassThrough
    def netfilter_all_tasks(vnic,network,friends,security_groups,node)
      []
    end

    def netfilter_isolation_tasks(vnic,friends,node)
      []
    end

    def netfilter_nat_tasks(vnic,network,node)
      []
    end

    def netfilter_secgroup_tasks(secgroup)
      []
    end

    def netfilter_drop_tasks(vnic,node)
      []
    end

    def netfilter_arp_isolation_tasks(vnic,friends,node)
      []
    end
  end

end