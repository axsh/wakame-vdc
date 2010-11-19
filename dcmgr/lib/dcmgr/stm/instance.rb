# -*- coding: utf-8 -*-

require 'statemachine'

module Dcmgr::Stm
  class Instance
    STM = Statemachine.build {
      startstate :pending
      superstate :instance_condition do
        trans :pending, :on_create, :starting
        trans :starting, :on_started, :running
        trans :running, :on_shutdown, :shuttingdown
        trans :shuttingdown, :on_terminated, :terminated
        
        event :on_fail, :failed
      end
      
      trans :failed, :on_fail, :failed
    }
    
    def initialize
    end
    
  end
end
