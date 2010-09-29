# -*- coding: utf-8 -*-
require 'statemachine'

module Dcmgr::Models
  class StoragePool < BaseNew
    taggable 'sp'
    with_timestamps

    inheritable_schema do
      String :agent_id, :null=>false
      String :export_path, :null=>false
      String :status, :null=>false
      Fixnum :offerring_disk_space, :null=>false, :unsigned=>true
      String :transport_type, :null=>false
      String :storage_type, :null=>false
    end

    one_to_many :volumes
    one_to_many :volume_snapshots
    
    many_to_one :storage_agents
    
    def to_hash_document
      h = self.values.dup
      h[:id] = h[:uuid] = self.canonical_uuid
      h
    end

    def state_machine
      model = self
      st = Statemachine.build do
        superstate :storage_condition do
          trans :registering, :on_success, :online
          trans :registering, :on_error, :degrade
          trans :online, :on_success, :online
          trans :online, :on_error, :degrade
          trans :degrade, :on_success, :online
          trans :degrade, :on_error, :degrade

          event :on_fail, :failed
          event :on_deregistered, :deregistered
        end

        trans :failed, :on_success, :online
        trans :failed, :on_error, :degrade
        trans :failed, :on_deregistered, :deregistered

        on_entry_of :registering, proc {
          model.status = :registering
        }

        on_entry_of :online, proc {
          model.status = :online
        }

        on_entry_of :degrade, proc {
          model.status = :degrade
        }

        on_entry_of :failed, proc {
          model.status = :failed
        }

        on_entry_of :deregistered, proc {
          model.status = :deregistered
        }
      end

      if self[:status]
        if st.has_state(self[:status].to_sym)
          st.state = self[:status].to_sym
        else
          raise "Unknown state: #{self[:status]}"
        end
      else
        st.reset
      end
      st
    end
  end
end
