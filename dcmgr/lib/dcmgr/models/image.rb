# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Metadata catalogs for bootable image file.
  class Image < AccountResource
    taggable 'wmi'
    with_timestamps

    BOOT_DEV_SAN=1
    BOOT_DEV_LOCAL=2

    # Possible source column data:
    # vdc volume:
    # {:type=>:vdcvol, :account_id=>'a-xxxxx', :snap_id=>'snap-xxxxxx'}
    plugin :serialization
    serialize_attributes :yaml, :source
    
    inheritable_schema do
      Fixnum :boot_dev_type, :null=>false, :default=>BOOT_DEV_SAN
      Text :source, :null=>false
      String :arch, :size=>10, :null=>false
      Text :description
      #Fixnum :parent_image_id

      String :state, :size=>20, :null=>false, :default=>:init.to_s
    end

    def validate
      unless [BOOT_DEV_SAN, BOOT_DEV_LOCAL].member?(self.boot_dev_type)
        errors.add(:boot_dev_type, "Invalid boot dev type: #{self.boot_dev_type}")
      end
      
      unless HostPool::SUPPORTED_ARCH.member?(self.arch)
        errors.add(:arch, "Unsupported arch type: #{self.arch}")
      end
    end
  end
end
