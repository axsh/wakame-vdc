# -*- coding: utf-8 -*-
require 'statemachine'

module Dcmgr::Models
  class Volume < AccountResource
    taggable 'vol'
    plugin :serialization, :yaml, :transport_information

    STATUS_TYPE_REGISTERING = 0
    STATUS_TYPE_ONLINE = 1
    STATUS_TYPE_OFFLINE = 2
    STATUS_TYPE_FAILED = 3

    STATE_TYPE_REGISTERING = 0
    STATE_TYPE_CREATING = 1
    STATE_TYPE_AVAILABLE = 2
    STATE_TYPE_ATTATING = 3
    STATE_TYPE_ATTACHED = 4
    STATE_TYPE_DETACHING = 5
    STATE_TYPE_FAILED = 6
    STATE_TYPE_DEREGISTERING = 7
    STATE_TYPE_DELETING = 8
    STATE_TYPE_DELETED = 9

    # STATE_MSGS = {
    #   STATE_TYPE_REGISTERING => :registering,
    #   STATE_TYPE_CREATING => :creating,
    #   STATE_TYPE_AVAILABLE => :available,
    #   STATE_TYPE_ATTATING => :attaching,
    #   STATE_TYPE_ATTACHED => :attached,
    #   STATE_TYPE_DETACHING => :detaching,n
    #   STATE_TYPE_FAILED => :failed,
    #   STATE_TYPE_DEREGISTERING => :deregistering,
    #   STATE_TYPE_DELETING => :deleting,
    #   STATE_TYPE_DELETED => :deleted
    # }

    # MSG_TO_ID = STATE_MSGS.invert

    inheritable_schema do
      Fixnum :storage_pool_id, :null=>false
      Fixnum :status, :null=>false, :default=>STATUS_TYPE_REGISTERING
      String :state, :null=>false, :default=> 'registering'
      Fixnum :size, :null=>false
      String :instance_id
      String :host_device_name
      String :guest_device_name
      String :export_path, :null=>false
      Text :transport_information
    end
    with_timestamps

    many_to_one :storage_pool

    class DiskError < RuntimeError; end
    class RequestError < RuntimeError; end

    def before_create
      # storage_poolに空き容量があるか調べる
      sp = self.storage_pool
      volume_size = Volume.dataset.where(:storage_pool_id=> self.storage_pool_id).get{sum(:size)}
      total_size = sp.offerring_disk_space - volume_size.to_i
      if self.size > total_size
        raise DiskError, "out of disk space"
      end

      super
    end

    def before_save
      self.updated_at = Time.now
      super
    end

    def self.delete_volume(account_id, uuid)
      v = self.dataset.where(:account_id=>account_id).where(:uuid=>uuid.split('-').last).first
      if v.state.to_sym != :available
        raise RequestError, "invalid delete request"
      end
      v.state = :deregistering
      v.save_changes
      v
    end

    def merge_pool_data
      sp = self.storage_pool
      v = self.to_hash_document
      unless v[:transport_information].nil?
        v[:transport_information] = YAML.load(v[:transport_information])
      end
      v.merge(:pool_name=>sp.values[:export_path].split('/').last)
    end

    def to_hash_document
      h = self.values.dup
      h[:id] = h[:uuid] = h[:export_path] = self.canonical_uuid
      h
    end

    # def state_machine
    #   model = self
    #   sm = Statemachine.build do
    #     superstate :volume_condition do
    #       trans :registering, :on_create, :creating
    #       trans :creating, :on_create, :available
    #       trans :available, :on_attach, :attaching
    #       trans :attaching, :on_attach, :attached
    #       trans :available, :on_create, :available
    #       trans :attached, :on_detach, :detaching
    #       trans :detaching, :on_detach, :attached
    #       trans :attached, :on_attach, :attached

    #       event :on_fail, :failed
    #       event :on_deregister, :deregistering
    #     end

    #     trans :failed, :on_create, :creating
    #     trans :failed, :on_fail, :failed
    #     trans :deregistering, :on_delete, :deleting
    #     trans :deleting, :on_delete, :deleted
    #     trans :deleted, :on_delete, :deleted

    #     on_entry_of :creating, proc {
    #       model.state = STATE_TYPE_CREATING
    #     }

    #     on_entry_of :available, proc {
    #       model.state = STATE_TYPE_AVAILABLE
    #       model.status = STATUS_TYPE_ONLINE
    #     }

    #     on_entry_of :attatinging, proc {
    #       model.state = STATE_TYPE_ATTATING 
    #     }

    #     on_entry_of :attached, proc {
    #       model.state = STATUS_TYPE_ATTACHED
    #     }

    #     on_entry_of :failed, proc {
    #       model.state = STATE_TYPE_FAILED
    #       model.status = STATUS_TYPE_FAILED
    #     }

    #     on_entry_of :deregistering, proc {
    #       model.state = STATE_TYPE_DEREGISTERING
    #     }

    #     on_entry_of :deleting, proc {
    #       model.state = STATE_TYPE_DELETING
    #     }

    #     on_entry_of :deleted, proc {
    #       model.state = STATE_TYPE_DELETED
    #       model.status = STATUS_TYPE_OFFLINE
    #     }

    #   end

    #   if self[:state]
    #     if sm.has_state(STATE_MSGS[self[:state]].to_sym)
    #       sm.state = STATE_MSGS[self[:state]].to_sym
    #     else
    #       raise "Unknown state: #{self[:state]}"
    #     end
    #   else
    #     sm.reset
    #   end
    #   sm
    # end

  end
end
