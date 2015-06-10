# -*- coding: utf-8 -*-

module Dcmgr::Constants::Instance
  STATE_SCHEDULING = "scheduling".freeze
  STATE_PENDING = "pending".freeze
  STATE_STARTING = "starting".freeze
  STATE_RUNNING = "running".freeze
  STATE_SHUTTING_DOWN = "shuttingdown".freeze
  STATE_TERMINATED = "terminated".freeze
  STATE_HALTING = "halting".freeze
  STATE_HALTED = "halted".freeze
  STATE_STOPPING = "stopping".freeze
  STATE_STOPPED = "stopped".freeze
  STATE_INITIALIZING = "initializing".freeze
  STATE_MIGRATING = "migrating".freeze

  STATES=[STATE_INITIALIZING,
          STATE_SCHEDULING,
          STATE_PENDING,
          STATE_STARTING,
          STATE_RUNNING,
          STATE_SHUTTING_DOWN,
          STATE_TERMINATED,
          STATE_HALTING,
          STATE_HALTED,
          STATE_STOPPING,
          STATE_STOPPED,
          STATE_MIGRATING,
         ].freeze

  MIGRATION_STATES=[STATE_RUNNING, STATE_HALTED].freeze

  STATUS_ONLINE = "online".freeze
  STATUS_OFFLINE = "offline".freeze
end
