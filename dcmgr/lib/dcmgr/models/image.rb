# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Metadata catalogs for bootable image file.
  class Image < AccountResource
    taggable 'wmi'
    accept_service_type

    BOOT_DEV_SAN=1
    BOOT_DEV_LOCAL=2

    many_to_one :backup_object, :class=>BackupObject, :dataset=> lambda { BackupObject.filter(:uuid=>self.backup_object_id[BackupObject.uuid_prefix.size + 1, 255]) }

    subset(:alives, {:deleted_at => nil})

    def_dataset_method(:alives_and_deleted) { |term_period=Dcmgr.conf.recent_terminated_instance_period|
      filter("deleted_at IS NULL OR deleted_at >= ?", (Time.now.utc - term_period))
    }

    plugin :serialization
    serialize_attributes :yaml, :features
    
    plugin ArchiveChangedColumn, :histories
    
    def after_initialize
      super
      unless self.features.is_a?(Hash) 
        self.features = {}
      end
    end

    def before_destroy
      if !Instance.lives.filter(:image_id=>self.canonical_uuid).empty?
        raise "There are one or more running instances refers this record."
      end
      
      super
    end

    def validate
      super
      
      unless [BOOT_DEV_SAN, BOOT_DEV_LOCAL].member?(self.boot_dev_type)
        errors.add(:boot_dev_type, "Invalid boot dev type: #{self.boot_dev_type}")
      end
      
      unless HostNode::SUPPORTED_ARCH.member?(self.arch)
        errors.add(:arch, "Unsupported arch type: #{self.arch}")
      end
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
      case key.to_sym
      when :virtio
        self.features[:virtio] = value
      else
        raise "Unsupported feature: #{key}"
      end

      self.changed_columns << :features
      self
    end

    def get_feature(key)
      self.features[key]
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.state = :deleted if self.state != :deleted
      self.deleted_at ||= Time.now
      self.save
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
    
    def entry_clone(&blk)
      self.class.entry_new(self.account, self.arch, self.boot_dev_type, self.file_format) do |i|
        i.display_name = self.display_name
        i.description = "#{self.description} (copy of #{self.canonical_uuid})"
        i.features = self.features
        i.root_device = self.root_device
        i.service_type = self.service_type
        i.instance_model_name = self.instance_model_name unless self.instance_model_name.nil?
        i.parent_image_id = self.canonical_uuid
        blk.call(i) if blk
      end
    end
    
  end
end
