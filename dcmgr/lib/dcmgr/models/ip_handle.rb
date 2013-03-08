# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class IpHandle < AccountResource
    include Dcmgr::Logger
    taggable 'ip'

    one_to_one :ip_lease, :class=>NetworkVifIpLease

    subset(:alives, {:deleted_at => nil})

    #
    # Sequel methods:
    #

    def validate
      super
    end

  end

end
