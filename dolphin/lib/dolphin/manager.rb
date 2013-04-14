# -*- coding: utf-8 -*-

require 'celluloid'
require 'pry'
module Dolphin
  class Manager < Celluloid::SupervisionGroup
    include Dolphin::Util

    trap_exit :actor_died

    def actor_died(actor, reason)
      logger :info, "Actor died"
      restart_actor(actor, "Breaked actor")
      logger :info, "Actor restarted"
    end

    def start
    end

    def shutdown
    end

    def run_workers
    end

    def terminate_workers
    end

    def run_request_handlers
    end

    def terminate_request_handlers
    end
  end
end