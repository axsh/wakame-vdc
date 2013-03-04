# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class IpLeaseHandle < AccountResource
    include Dcmgr::Logger
    taggable 'ipl'

  end

end
