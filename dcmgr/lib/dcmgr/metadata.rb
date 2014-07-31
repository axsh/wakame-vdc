# -*- coding: utf-8 -*-

module Dcmgr::Metadata

  # Factory method
  def self.md_type(instance_hash)
    # In the future we can use this to provide different types of metadata items
    # depending on the instance_hash.

    # For now we have only one type of metadata items so we're making one of those.
    AWS.new(instance_hash)
  end

  class MetadataType
    def initialize(instance_hash)
      @inst = instance_hash
    end

    def get_items
      raise NotImplementedError,
        "Classes inheriting from MDType must override the get_items method"
    end
  end
end
