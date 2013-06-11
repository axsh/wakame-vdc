# -*- coding: utf-8 -*-

module Dcmgr::Models
  class IpPoolDcNetwork < BaseNew
    many_to_one :ip_pool
    many_to_one :dc_network
  end
end
