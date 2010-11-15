# -*- coding: utf-8 -*-
require 'statemachine'

module Dcmgr::Models
  class Volume < AccountResource
    taggable 'vol'

    STATUS_TYPE_REGISTERING = "registering"
    STATUS_TYPE_ONLINE = "online"
    STATUS_TYPE_OFFLINE = "offline"
    STATUS_TYPE_FAILED = "failed"

    STATE_TYPE_REGISTERING = "registering"
    STATE_TYPE_CREATING = "creating"
    STATE_TYPE_AVAILABLE = "available"
    STATE_TYPE_ATTATING = "attating"
    STATE_TYPE_ATTACHED = "attached"
    STATE_TYPE_DETACHING = "detaching"
    STATE_TYPE_FAILED = "failed"
    STATE_TYPE_DEREGISTERING = "deregistering"
    STATE_TYPE_DELETING = "deleting"
    STATE_TYPE_DELETED = "deleted"

    inheritable_schema do
      Fixnum :storage_pool_id, :null=>false
      String :status, :null=>false, :default=>STATUS_TYPE_REGISTERING
      String :state, :null=>false, :default=>STATE_TYPE_REGISTERING
      Fixnum :size, :null=>false
      Fixnum :instance_id
      String :snapshot_id
      String :host_device_name
      String :guest_device_name
      String :export_path, :null=>false
      Text :transport_information
      Time :deleted_at
      Time :attached_at
      Time :detached_at
    end
    with_timestamps

    # serialization plugin must be defined at the bottom of all class
    # method calls.
    # Possible column data:
    # iscsi:
    # {:iqn=>'iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc', :lun=>0}
    plugin :serialization, :yaml, :transport_information
    
    many_to_one :storage_pool
    many_to_one :instance

    class DiskError < RuntimeError; end
    class RequestError < RuntimeError; end

    def before_create
      # check the volume size
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

    def self.get_list(account_id, *args)
      data = args.first
      vl = self.dataset.where(:account_id=>account_id)
      vl = vl.limit(data[:limit], data[:start]) if data[:start] && data[:limit]
      if data[:target] && data[:sort]
        vl = case data[:sort]
             when 'desc'
               vl.order(data[:target].to_sym.desc)
             when 'asc'
               vl.order(data[:target].to_sym.asc)
             end
      end
      if data[:target] && data[:filter]
        filter = case data[:target]
                 when 'uuid'
                   data[:filter].split('vol-').last
                 else
                   data[:filter]
                 end
        vl = vl.grep(data[:target].to_sym, "%#{filter}%")
      end
      vl.all.map{|row|
        row.to_hash_document
      }
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
      v = self.to_hash_document
      v.merge(:storage_pool=>storage_pool.to_hash_document)
    end

    def to_hash_document
      h = self.values.dup
      h[:id] = h[:uuid] = h[:export_path] = self.canonical_uuid
      # yaml -> hash translation
      h[:transport_information]=self.transport_information
      h
    end

    def create_snapshot(account_id)
      vs = VolumeSnapshot.create(:account_id=>account_id,
                                 :storage_pool_id=>self.storage_pool_id,
                                 :origin_volume_id=>self.canonical_uuid,
                                 :size=>self.size)
    end
  end
end
