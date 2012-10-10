# -*- coding: utf-8 -*-

module Dcmgr::Tags
  include Dcmgr
  KEY_MAP={10=>:NetworkGroup, 11=>:HostNodeGroup, 12=>:StorageNodeGroup}.freeze
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

  class NetworkGroup < Models::Tag
    taggable 'nwg'
    def accept_mapping?(to)
      to.is_a?(Dcmgr::Models::Network)
    end

    def pick()
      lst = mapped_uuids.map { |t|
        Dcmgr::Models::Network[t.uuid]
      }.sort_by{ |n|
        n.available_ip_nums
      }.reverse.first
    end
  end

  class HostNodeGroup < Models::Tag
    taggable 'hng'
    def accept_mapping?(to)
      to.is_a?(Dcmgr::Models::HostNode)
    end

    def pick(instance)
      mapped_uuids.map { |t|
        Dcmgr::Models::HostNode[t.uuid]
      }.find_all { |h|
        h.check_capacity(instance)
      }.sort_by { |h|
        h.instances.count
      }.reverse.first
    end
  end

  class StorageNodeGroup < Models::Tag
    taggable 'sng'
    def accept_mapping?(to)
      to.is_a?(Dcmgr::Models::StorageNode)
    end
  end
end
