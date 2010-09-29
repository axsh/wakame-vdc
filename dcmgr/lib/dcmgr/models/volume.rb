# -*- coding: utf-8 -*-
require 'statemachine'

module Dcmgr::Models
  class Volume < AccountResource
    taggable 'vol'

    STATUS_TYPE_CREATING = 1
    STATUS_TYPE_AVAILABLE = 2
    STATUS_TYPE_ATTACHED = 3
    STATUS_TYPE_DELETING = 4

    inheritable_schema do
      Fixnum :storage_pool_id, :null=>false
      Fixnum :status, :null=>false
      String :state, :null=>false
      Fixnum :size, :null=>false
      Fixnum :target
      String :export_path, :null=>false
      String :initiater_device_name, :null=>false
    end
    with_timestamps

    many_to_one :storage_pool

    def to_hash_document
      h = self.values.dup
      h[:id] = h[:uuid] = self.canonical_uuid
      h
    end

    def state_machine
      model = self
      sm = Statemachine.build do
        superstate :volume_condition do
          trans :registering, :on_create, :creating
          trans :creating, :on_create, :available
          trans :available, :on_attach, :attached
          trans :available, :on_create, :available
          trans :attached, :on_detach, :available
          trans :attached, :on_attach, :attached

          event :on_fail, :failed
          event :on_delete, :deleting
        end

        on_entry_of :registering, proc {
          model.state = :registering
        }

        on_entry_of :creating, proc {
          model.state = :creating
        }

        on_entry_of :available, proc {
          model.state = :available
        }

        on_entry_of :attached, proc {
          model.state = :attached
        }

      end

      if self[:state]
        if sm.has_state(self[:state].to_sym)
          sm.state = self[:state].to_sym
        else
          raise "Unknown state: #{self[:state]}"
        end
      else
        sm.reset
      end
      sm
    end

  end
end
