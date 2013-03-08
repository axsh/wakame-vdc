# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class IpHandle < AccountResource
    include Dcmgr::Logger
    taggable 'ip'

    subset(:alives, {:deleted_at => nil})

    #
    # Sequel methods:
    #

    def validate
      super
    end

  end

end
