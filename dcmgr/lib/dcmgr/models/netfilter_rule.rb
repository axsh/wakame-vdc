# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetfilterRule < BaseNew

    many_to_one :netfilter_group

    def to_hash
      {
        :permission => permission,
      }
    end

  end
end
