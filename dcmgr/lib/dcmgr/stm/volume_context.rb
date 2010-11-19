# -*- coding: utf-8 -*-
require 'statemachine'

module Dcmgr::Stm
  class VolumeContext < OpenStruct
    attr_reader :stm

    def initialize(volume_id=nil)
      super({:volume_id => volume_id,
              :export_path => nil,
              :transport_information => nil,
              :instance_id => nil,
              :host_device_name => nil,
              :guest_device_name => nil,
              :deleted_at => nil,
              :attached_at => nil,
              :detached_at => nil,
            })
      @stm = Statemachine.build {
        startstate :registering
        superstate :volume_condition do
          trans :registering, :on_create, :creating
          trans :creating, :on_register, :available
          trans :available, :on_attach, :attaching
          trans :attaching, :on_attach, :attached
          trans :attached, :on_detach, :detaching
          trans :detaching, :on_detach, :available

          event :on_fail, :failed
          event :on_deregister, :deregistering
        end

        trans :failed, :on_create, :creating
        trans :failed, :on_register, :available
        trans :failed, :on_fail, :failed
        trans :failed, :on_deregister, :deleting
        trans :failed, :on_delete, :deleted
        trans :deregistering, :on_delete, :deleting
        trans :deleting, :on_delete, :deleted
        trans :deleted, :on_delete, :deleted
      }
      @stm.context = self
    end

    def state
      @stm.state
    end
    
    def to_hash(hash={})
      @table.dup.merge({:state=>@stm.state}).merge(hash)
    end

    def on_delete
      self.deleted_at = Time.now
    end

    def on_attach
      self.attached_at = Time.now
    end

    def on_detach
      self.detached_at = Time.now
    end
  end
end
