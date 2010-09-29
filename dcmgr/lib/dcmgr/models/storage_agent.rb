# -*- coding: utf-8 -*-

module Dcmgr::Models
  class StorageAgent < BaseNew
    with_timestamps

    inheritable_schema do
      String :agent_id, :null=>false
      String :status, :null=>false
    end

    one_to_many :storage_pools
  end
end
