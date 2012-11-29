# -*- coding: utf-8 -*-

module Dcmgr::Constants::Tag
  KEY_MAP={10=>:NetworkGroup, 11=>:HostNodeGroup, 12=>:StorageNodeGroup}.freeze
  MODEL_MAP=KEY_MAP.invert.freeze
end
