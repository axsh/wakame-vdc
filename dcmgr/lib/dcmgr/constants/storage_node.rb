# -*- coding: utf-8 -*-

module Dcmgr::Constants
  module StorageNode
    BACKINGSTORE_ZFS = 'zfs'.freeze
    BACKINGSTORE_RAW = 'raw'.freeze
    BACKINGSTORE_IFS = 'ifs'.freeze

    SUPPORTED_BACKINGSTORE = [BACKINGSTORE_ZFS, BACKINGSTORE_RAW, BACKINGSTORE_IFS].freeze

    STATUS_ONLINE='online'.freeze
    STATUS_OFFLINE='offline'.freeze
  end
end
