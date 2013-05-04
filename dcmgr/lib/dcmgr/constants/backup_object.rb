# -*- coding: utf-8 -*-

module Dcmgr::Constants
  module BackupObject
    STATE_CREATING = "creating".freeze
    STATE_PENDING = "pending".freeze
    STATE_AVAILABLE = "available".freeze
    STATE_DELETED = "deleted".freeze
    
    STATES=[STATE_CREATING, STATE_PENDING, STATE_AVAILABLE, STATE_DELETED].freeze

    CONTAINER_FORMAT={:tgz=>['tar.gz', 'tgz'], :tar=>['tar'], :gz=>['gz'], :none=>[]}.freeze
    CONTAINER_FORMAT_NAMES=CONTAINER_FORMAT.keys.freeze
    CONTAINER_EXTS=Hash[*CONTAINER_FORMAT.map{|k,v|
                          v.map { |v2|
                            [v2, k]
                          }
                        }.flatten].freeze

    CLONED_FIELDS_AT_TRANSFER=[:account_id,
                               :display_name,
                               :service_type,
                               :description,
                               :size,
                               :allocation_size,
                               :container_format,
                               :checksum
                              ].freeze
  end
end
