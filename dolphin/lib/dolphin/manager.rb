# -*- coding: utf-8 -*-

require 'celluloid'

module Dolphin
  class Manager < Celluloid::SupervisionGroup
    include Dolphin::Util

    trap_exit :worker_died

    def worker_died(actor, reason)
      info "actor died"
      restart_actor(actor, "Hoge")
      info "actor restarted"
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