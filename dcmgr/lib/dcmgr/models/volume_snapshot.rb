# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VolumeSnapshot < AccountResource
    taggable 'snap'

    inheritable_schema do
      Fixnum :storage_pool_id, :null=>false
      String :origin_volume_id, :null=>false
      Fixnum :size, :null=>false
      Fixnum :status, :null=>false, :default=>0
    end
    with_timestamps

    many_to_one :storage_pool

    def to_hash_document
      h = self.values.dup
      h[:id] = h[:uuid] = self.canonical_uuid
      h
    end
  end
end
