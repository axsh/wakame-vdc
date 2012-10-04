# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Instance < Base
    namespace :instance
    M = Dcmgr::Models
    include Dcmgr::Constants::Instance

    desc "force-state UUID STATE", "Force an instance's state to chance in the database without any other action taken by Wakame. Use only if you know what you're doing!"
    def force_state(uuid,state)
      raise "Invalid state: #{state} possible states are: [#{STATES.join(',')}]" unless STATES.member?(state)
      modify(M::Instance,uuid,{:state => state})
    end

    desc "show [UUID] [options]", "Show onstance(s)"
    def show(uuid=nil)
    end

  end
end
