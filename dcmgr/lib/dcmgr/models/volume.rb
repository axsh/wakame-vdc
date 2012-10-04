# -*- coding: utf-8 -*-

module Dcmgr::Models
  class Volume < AccountResource
    taggable 'vol'
    accept_service_type

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
    plugin ChangedColumnEvent, :accounting_log => [:state, :size]

    subset(:lives, {:deleted_at => nil})
    subset(:alives, {:deleted_at => nil})

    def_dataset_method(:alives_and_deleted) { |term_period=Dcmgr.conf.recent_terminated_instance_period|
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - term_period))
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
      if self.size > sp.free_disk_space
        raise CapacityError, "Allocation exceeds storage node blank size: #{self.size(MB)} MB (#{self.canonical_uuid}) > #{sp.free_disk_space(MB)} MB (#{sp.canonical_uuid})"
      end
    end

    def validate
      # do not run validation if the row is maked as deleted.
      return true if self.deleted_at

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

    def entry_delete()
      if self.state.to_sym != :available
        raise RequestError, "invalid delete request"
      end
      self.state = :deleting
      self.save_changes
      self
    end

    def merge_pool_data
      v = self.to_hash.merge(:storage_node=>storage_node.to_hash)
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

    SNAPSHOT_READY_STATES = [:attached, :available].freeze
    ONDISK_STATES = [:available, :attaching, :attached, :detaching].freeze

    def ready_to_take_snapshot?
      SNAPSHOT_READY_STATES.member?(self.state.to_sym)
    end

    def ondisk_state?
      ONDISK_STATES.member?(self.state.to_sym)
    end

    def entry_new_backup_object(bkst, account_id=nil, &blk)
      BackupObject.entry_new(bkst,
                             (account_id || self.account_id),
                             self.size * 1024 * 1024,
                             &blk)
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.state = :deleted if self.state != :deleted
      self.status = :offline if self.status != :offline
      self.save
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

    def on_changed_accounting_log(changed_column)
      AccountingLog.record(self, changed_column)
    end

    include Dcmgr::Helpers::ByteUnit

    def size(byte_unit=B)
      convert_byte(self[:size], byte_unit)
    end

  end
end
