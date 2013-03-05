# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class IpPool < AccountResource
    include Dcmgr::Logger
    taggable 'ipp'

    many_to_many :dc_networks, :join_table=>:ip_pool_dc_networks

    subset(:alives, {:deleted_at => nil})

  end

end
