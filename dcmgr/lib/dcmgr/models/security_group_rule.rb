# -*- coding: utf-8 -*-

module Dcmgr::Models
  class SecurityGroupRule < BaseNew

    many_to_one :security_group

    def to_hash
      {
        :permission => permission,
      }
    end

  end
end
