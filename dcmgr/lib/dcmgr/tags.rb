# -*- coding: utf-8 -*-

module Dcmgr::Tags
  include Dcmgr
  KEY_MAP={10=>:NetworkPool, 11=>:HostPool, 12=>:StoragePool}.freeze
  MODEL_MAP=KEY_MAP.invert.freeze

  def self.type_id(class_or_sym)
    k = case class_or_sym
    when String, Symbol
      class_or_sym.to_sym
    when Class
      class_or_sym.to_s.split('::').last.to_sym
    end

    MODEL_MAP[k] || raise("Unknown key to get type_id: #{class_or_sym}")
  end
  
  class NetworkPool < Models::Tag
    def accept_mapping?(to)
      to.is_a?(Dcmgr::Models::Network)
    end

    def networks_dataset
      TagMappings.filter()
    end
  end
  
  class HostPool < Models::Tag
    def accept_mapping?(to)
      to.is_a?(Dcmgr::Models::HostNode)
    end
  end
  
  class StoragePool < Models::Tag
    def accept_mapping?(to)
      to.is_a?(Dcmgr::Models::StorageNode)
    end
  end
end
