# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetworkVifSecurityGroup < BaseNew

    many_to_one :network_vif
    many_to_one :security_group
  end
end
