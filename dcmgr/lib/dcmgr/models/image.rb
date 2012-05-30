# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Metadata catalogs for bootable image file.
  class Image < AccountResource
    taggable 'wmi'
    accept_service_type

    BOOT_DEV_SAN=1
    BOOT_DEV_LOCAL=2

    many_to_one :backup_object, :class=>BackupObject, :dataset=> lambda { BackupObject.filter(:uuid=>self.backup_object_id[BackupObject.uuid_prefix.size + 1, 255]) }

    plugin :serialization
    serialize_attributes :yaml, :features
    
    def after_initialize
      super
      unless self.features.is_a?(Hash) 
        self.features = {}
      end
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
    
  end
end
