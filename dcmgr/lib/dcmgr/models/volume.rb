# -*- coding: utf-8 -*-

module Dcmgr::Models
  class Volume < AccountResource
    taggable 'vol'
    accept_service_type
    include Dcmgr::Constants::Volume

    many_to_one :instance

    plugin ArchiveChangedColumn, :histories
    plugin ChangedColumnEvent, :accounting_log => [:state, :size]
    plugin Plugins::ResourceLabel

    subset(:lives, {:deleted_at => nil})
    subset(:alives, {:deleted_at => nil})
    dataset_module do
      def attached
        filter_by_state(STATE_ATTACHED)
      end
      
      def filter_by_state(state)
        filter({:state=>state})
      end
    end

    def_dataset_method(:alives_and_deleted) { |term_period=Dcmgr.conf.recent_terminated_instance_period|
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - term_period))
    }

    many_to_one :backup_object, :class=>BackupObject, :dataset=> lambda { BackupObject.filter(:uuid=>self.backup_object_id[BackupObject.uuid_prefix.size + 1, 255]) }

    # serialization plugin must be defined at the bottom of all class
    # method calls.
    plugin :serialization, :yaml, :request_params

    class CapacityError < RuntimeError; end
    class RequestError < RuntimeError; end

    def validate_storage_node_assigned(sp)
      if self.size > sp.free_disk_space
        raise CapacityError, "Allocation exceeds storage node blank size: #{self.size(MB)} MB (#{self.canonical_uuid}) > #{sp.free_disk_space(MB)} MB (#{sp.canonical_uuid})"
      end
    end

    def self.find_candidate_device_name(device_names)
      # sort %w(hdaz hdaa hdc hdz hdn) => ["hdc", "hdn", "hdz", "hdaa", "hdaz"]
      device_names = device_names.sort{|a,b| a.size == b.size ? a <=> b :  a.size <=> b.size }
      return nil if device_names.empty?
      # find candidate device name from unused successor of device_names.
      #   %w(hdaz hdaa hdc hdz hdn) => hdd (= "hdc".succ)
      device_names.zip(device_names.dup.tap(&:shift)).inject(device_names.first) {|r,l|  r.succ == l.last ? l.last : r }.succ
    end
    
    def validate
      # do not run validation if the row is maked as deleted.
      return true if self.deleted_at

      errors.add(:size, "Invalid volume size: #{self.size}") if self.size < 0

      if self.instance
        # check if volume parameters are conformant for hypervisor.
        hypervisor_class = Dcmgr::Drivers::Hypervisor.driver_class(self.instance.hypervisor.to_sym)
        hypervisor_class.policy.validate_volume_model(self)

        if self.guest_device_name.nil?
          errors.add(:guest_device_name, "require to have device name")
        end

        # uniqueness check for device names per instance
        names = self.instance.volumes_dataset.attached.all.map{|v| v.guest_device_name }
        duplicate_names = (names - names.uniq)
        unless duplicate_names.empty?
          errors.add(:guest_device_nam, "found duplicate device name (#{duplicate_names.join(', ')}) for #{instance.caonnical_uuid}")
        end
      end
      
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
      if self.state.to_s != STATE_AVAILABLE
        raise RequestError, "invalid delete request"
      end
      self.state = STATE_DELETING
      self.save_changes
      self
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

    def to_hash
      super().merge(:is_local_volume=>local_volume?,
                    :volume_device=>(self.volume_device.nil? ? nil : self.volume_device.to_hash)
                    )
    end

    def local_volume?
      self.volume_type == 'Dcmgr::Models::LocalVolume'
    end

    def ready_to_take_snapshot?
      SNAPSHOT_READY_STATES.member?(self.state.to_s)
    end

    def ondisk_state?
      ONDISK_STATES.member?(self.state.to_s)
    end

    def entry_new_backup_object(bkst, account_id=nil, &blk)
      BackupObject.entry_new(bkst,
                             (account_id || self.account_id),
                             self.size * 1024 * 1024,
                             &blk)
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

    # Sequel's class_table_inheritance plugin caused many changes for our
    # model base class. so I stopped to use it.
    def volume_class
      self.volume_type.split('::').unshift(Object).inject{|r, i| r.const_get(i) }
    end

    def volume_device
      self.volume_class.find(:id=>self.id.to_i)
    end

    def boot_volume?
      self.instance && self.instance.boot_volume_id == self.canonical_uuid
    end

    def on_changed_accounting_log(changed_column)
      AccountingLog.record(self, changed_column)
    end

    include Dcmgr::Helpers::ByteUnit

    def size(byte_unit=B)
      convert_byte(self[:size], byte_unit)
    end

    def detach_from_instance
      self.instance_id = nil
      self.state = STATE_AVAILABLE
      self.save_changes
    end

    def create_backup_object(account, &blk)
      bo = BackupObject.create(:account_id => account.canonical_uuid,
                               :service_type => self.service_type,
                               :allocation_size=>self.size,
                               :source_volume_id=>self.canonical_uuid,
                               )
      blk.call(bo)
      bo.save_changes
      bo
    end
    
    private
    def _destroy_delete
      self.deleted_at ||= Time.now
      self.state = STATE_DELETED if self.state != STATE_DELETED
      self.status = STATUS_OFFLINE if self.status != STATUS_OFFLINE
      self.save_changes
    end
  end
end
