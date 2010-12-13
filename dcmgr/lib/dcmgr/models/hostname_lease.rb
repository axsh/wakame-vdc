# -*- coding: utf-8 -*-

module Dcmgr::Models
  # hostname table for each instance to ensure uniqueness.
  class HostnameLease < BaseNew

    inheritable_schema do
      String :account_id, :null=>false, :size=>50
      String :hostname, :null=>false, :size=>32

      index [:account_id, :hostname], {:unique=>true}
    end
    with_timestamps
  end
end
