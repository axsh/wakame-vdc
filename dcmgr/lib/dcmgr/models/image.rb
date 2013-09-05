# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Metadata catalogs for bootable image file.
  class Image < AccountResource
    taggable 'wmi'
    accept_service_type

    include Dcmgr::Constants::Image
    
    plugin Plugins::ResourceLabel
      
    many_to_one :backup_object, :class=>BackupObject, :dataset=> lambda { BackupObject.filter(:uuid=>self.backup_object_id[BackupObject.uuid_prefix.size + 1, 255]) }

    subset(:alives, {:deleted_at => nil})

    def_dataset_method(:alives_and_deleted) { |term_period=Dcmgr.conf.recent_terminated_instance_period|
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - term_period))
    }

    plugin :serialization
    serialize_attributes :yaml, :features, :volumes, :vifs

    plugin ArchiveChangedColumn, :histories

    def after_initialize
      super
      self.features ||= {}
      self.volumes ||= []
      self.vifs ||= []
    end

    def validate
      super

      unless BOOT_DEV_FLAGS.member?(self.boot_dev_type)
        errors.add(:boot_dev_type, "Invalid boot dev type: #{self.boot_dev_type}")
      end

      unless HostNode::SUPPORTED_ARCH.member?(self.arch)
        errors.add(:arch, "Unsupported arch type: #{self.arch}")
      end

      self.features.keys.each { |k|
        unless FEATURES.member?(k.to_s)
          errors.add(:features, "Unknown feature flag: #{k.to_s}")
          break
        end
      }
    end

    # note on "lookup_account_id":
    def to_api_document(lookup_account_id)
      h = super()
      if self.account_id == lookup_account_id
      else
        if h[:source][:type] == :http
          # do not show URI for non-owner accounts.
          h[:source][:uri] = nil
        end
      end
      h
    end

    # TODO: more proper key&value validation.
    # Handles the feature blob column.
    def set_feature(key, value)
      if FEATURES.member?(key.to_s)
        self.features[key.to_sym] = value
      else
        raise "Unsupported feature: #{key}"
      end

      self.changed_columns << :features
      self
    end

    def get_feature(key)
      self.features[key]
    end

    def self.entry_new(account, arch, boot_dev_type, file_format, &blk)
      img = self.new
      img.account_id = account.canonical_uuid
      img.arch = arch
      img.boot_dev_type = boot_dev_type
      img.file_format = file_format
      blk.call(img)
      img.save
    end

    NOT_CLONED_COLUMNS=[:id,
                        :uuid,
                        :created_at,
                        :updated_at,
                        :deleted_at,
                       ].freeze

    def entry_clone(&blk)
      src = self.values.dup.tap { |i|
        NOT_CLONED_COLUMNS.each { |k|
          i.delete(k)
        }
      }
      self.class.new(src) do |i|
        # copy serializable fields
        i.features = self.features
        i.volumes = self.volumes
        i.vifs = self.vifs

        # fields slightly modified.
        i.parent_image_id = self.canonical_uuid
        blk.call(i) if blk
      end.save
    end

    def create_volume(account=nil)
      bo = self.backup_object || raise("Unknown backup object: #{self.backup_object_id}")

      account ||= self.account

      vol = bo.create_volume(account)
      vol.volume_type = case self.boot_dev_type
                        when BOOT_DEV_LOCAL
                          LocalVolume.to_s
                        when BOOT_DEV_SAN
                          nil
                        else
                          raise "unknown boot device type: #{self.boot_dev_type}"
                        end
      vol.save

      vol
    end

    private
    def before_destroy
      if !Instance.alives.filter(:image_id=>self.canonical_uuid).empty?
        raise "There are one or more running instances refers this record."
      end

      super
    end

    def before_validation
      # symbolize feature's key
      self.features.keys.each { |k|
        if k.is_a?(String) && FEATURES.member?(k.to_s)
          self.features[k.to_sym] = self.features.delete(k)
        end
      }
    end

    def _destroy_delete
      self.deleted_at ||= Time.now
      self.state = STATE_DELETED if self.state != STATE_DELETED
      self.save_changes
    end
  end
end
