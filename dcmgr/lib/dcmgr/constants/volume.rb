# -*- coding: utf-8 -*-

module Dcmgr::Constants
  module Volume
    STATUS_REGISTERING = "registering".freeze
    STATUS_ONLINE = "online".freeze
    STATUS_OFFLINE = "offline".freeze
    STATUS_FAILED = "failed".freeze

    STATE_REGISTERING = "registering".freeze
    STATE_CREATING = "creating".freeze
    STATE_AVAILABLE = "available".freeze
    STATE_ATTACHING = "attatching".freeze
    STATE_ATTACHED = "attached".freeze
    STATE_DETACHING = "detaching".freeze
    STATE_FAILED = "failed".freeze
    STATE_DEREGISTERING = "deregistering".freeze
    STATE_DELETING = "deleting".freeze
    STATE_DELETED = "deleted".freeze

    STATES=[STATE_CREATING, STATE_AVAILABLE, STATE_ATTACHING,
            STATE_ATTACHED,
            STATE_DETACHING,
            STATE_DELETING,
            STATE_DELETED].freeze

    SNAPSHOT_READY_STATES = [STATE_ATTACHED, STATE_AVAILABLE].freeze
    ONDISK_STATES = [STATE_AVAILABLE, STATE_ATTACHING, STATE_ATTACHED, STATE_DETACHING].freeze

  end
end
