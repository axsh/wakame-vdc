# -*- coding: utf-8 -*-

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

    many_to_one :storage_node, :after_set=>:validate_storage_node_assigned
    many_to_one :instance

    plugin ArchiveChangedColumn, :histories
    
    subset(:lives, {:deleted_at => nil})

    RECENT_TERMED_PERIOD=(60 * 15)
    # lists the volumes are available and deleted within
    # RECENT_TERMED_PERIOD sec.
    def_dataset_method(:alives_and_recent_termed) {
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - RECENT_TERMED_PERIOD))
    }
    
    # serialization plugin must be defined at the bottom of all class
    # method calls.
    # Possible column data:
    # iscsi:
    # {:iqn=>'iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc', :lun=>0}
    plugin :serialization, :yaml, :transport_information
    plugin :serialization, :yaml, :request_params
    
    class CapacityError < RuntimeError; end
    class RequestError < RuntimeError; end

    def validate_storage_node_assigned(sp)
      unless sp.is_a?(StorageNode)
        raise "unknown class: #{sp.class}"
      end
      volume_size = sp.volumes_dataset.lives.sum(:size).to_i
      # check if the sum of available volume and new volume is under
      # the limit of offering capacity.
      total_size = sp.offering_disk_space - volume_size.to_i
      if self.size > total_size
        raise CapacityError, "Allocation exceeds storage node blank size: #{}"
      end
    end
    
    def validate
      # do not run validation if the row is maked as deleted.
      return true if self.deleted_at

      if new?
        # TODO: Here may not be the right place for capacity validation.
        per_account_total = self.class.filter(:account_id=>self.account_id).lives.sum(:size).to_i
        if self.account.quota.volume_total_size < per_account_total + self.size.to_i
          raise CapacityError, "Allocation exceeds account's quota: #{self.account.quota.volume_total_size}, #{self.size.to_i}, #{per_account_total}"
        end
      end

      errors.add(:size, "Invalid volume size.") if self.size == 0
      
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
        row.to_api_document
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
      v = self.to_hash
      v.merge(:storage_node=>storage_node.to_hash)
    end

    def to_hash
      h = super
      # yaml -> hash translation
      h[:transport_information]=self.transport_information
      h
    end

    # Hash data for API response.
    def to_api_document
      h = {
        :id => self.canonical_uuid,
        :uuid => self.canonical_uuid,
        :size => self.size,
        :snapshot_id => self.snapshot_id,
        :created_at => self.created_at,
        :attached_at => self.attached_at,
        :state => self.state,
        :instance_id => (self.instance && self.instance.canonical_uuid),
        :deleted_at => self.deleted_at,
        :detached_at => self.detached_at,
      }
    end
    
    def ready_to_take_snapshot?
      %w(available attached).member?(self.state)
    end

    def create_snapshot(account_id)
      vs = VolumeSnapshot.create(:account_id=>account_id,
                                 :storage_node_id=>self.storage_node_id,
                                 :origin_volume_id=>self.canonical_uuid,
                                 :size=>self.size)
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.state = :deleted if self.state != :deleted
      self.status = :offline if self.status != :offline
      self.save
    end

    def snapshot
      VolumeSnapshot[self.snapshot_id]
    end

    def self.entry_new(account, size, params, &blk)
      # Mash is passed in some cases.
      raise ArgumentError unless params.class == ::Hash
      v = self.new &blk
      v.account_id = account.canonical_uuid
      v.size = size
      v.request_params = params
      v
    end
      
  end
end
