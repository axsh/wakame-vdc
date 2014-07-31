# -*- coding: utf-8 -*-

module Dcmgr::Metadata

  # Factory method
  def self.md_type(instance)
    # In the future we can use this to provide different types of metadata items
    # depending on the instance.

    # For now we have only one type of metadata items so we're making one of those.
    AWS.new(instance)
  end

  class MetadataType
    def initialize(instance)
      @inst = instance
    end

    def get_items
      raise NotImplementedError,
        "Classes inheriting from MDType must override the get_items method"
    end
  end
end
