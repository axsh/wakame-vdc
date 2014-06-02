# -*- coding: utf-8 -*-

module Dcmgr::Constants
  module BackupObject
    STATE_CREATING = "creating".freeze
    STATE_PENDING = "pending".freeze
    STATE_AVAILABLE = "available".freeze
    STATE_DELETED = "deleted".freeze
    STATE_PURGED = "purged".freeze

    STATES=[STATE_CREATING, STATE_PENDING, STATE_AVAILABLE, STATE_DELETED].freeze
    ALLOW_INSTANCE_DESTROY_STATES=[STATE_AVAILABLE, STATE_DELETED, STATE_PURGED].freeze
    ALLOW_INSTANCE_POWERON_STATES=ALLOW_INSTANCE_DESTROY_STATES

    CONTAINER_FORMAT={:tgz=>['tar.gz', 'tgz'], :tar=>['tar'], :gz=>['gz'], :none=>[], :raw=>['raw']}.freeze
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
