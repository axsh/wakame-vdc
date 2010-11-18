# -*- coding: utf-8 -*-
require 'statemachine'

module Dcmgr::Stm
  class SnapshotContext < OpenStruct

    attr_reader :stm

    def initialize(snapshot_id=nil)
      super({:snapshot_id=>snapshot_id})
      @stm = Statemachine.build {
        trans :registering, :on_create, :creating
        trans :creating, :on_create, :available
        trans :available, :on_delete, :deleting
        trans :deleting, :on_delete, :deleted

        trans :registering, :on_fail, :failed
        trans :creating, :on_fail, :failed
        trans :available, :on_fail, :failed
        trans :deleting, :on_fail, :failed
      }
      @stm.context = self
    end

    def state
      @stm.state
    end

    def to_hash
      @table.dup.merge({:state=>@stm.state})
    end
  end
end
