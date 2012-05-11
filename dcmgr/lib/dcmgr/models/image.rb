# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Metadata catalogs for bootable image file.
  class Image < AccountResource
    taggable 'wmi'
    accept_service_type

    BOOT_DEV_SAN=1
    BOOT_DEV_LOCAL=2

    # serialize plugin must be defined at the bottom of all class
    # method calls.
    # Possible source column data:
    # {:snapshot_id=>'snap-xxxxxx'}
    # {:uri=>'http://localhost/xxx/xxx'}
    plugin :serialization
    serialize_attributes :yaml, :source, :features
    
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
      
      # validate source
      md = self.source
      case self.boot_dev_type
      when BOOT_DEV_LOCAL
        errors.add(:source, "Unknown image URI") if md[:uri].nil? || md[:uri] == ''
      when BOOT_DEV_SAN
        errors.add(:source, "Unknown snapshot ID") if md[:snapshot_id].nil? || md[:snapshot_id] == '' || VolumeSnapshot[md[:snapshot_id]].nil?
      end
    end

    # note on "lookup_account_id":
    # the source column sometime contains the information which
    # should not be shown to other accounts. so that the method takes
    # an argument who is looking into then filters the data in source
    # column accordingly.
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
