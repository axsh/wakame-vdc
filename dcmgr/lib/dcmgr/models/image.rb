# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Metadata catalogs for bootable image file.
  class Image < AccountResource
    taggable 'wmi'
    with_timestamps

    BOOT_DEV_SAN=1
    BOOT_DEV_LOCAL=2

    inheritable_schema do
      Fixnum :boot_dev_type, :null=>false, :default=>BOOT_DEV_SAN
      Text :source, :null=>false
      String :arch, :size=>10, :null=>false
      Text :description
      Boolean :is_public, :null=>false, :default=>false
      #Fixnum :parent_image_id

      String :state, :size=>20, :null=>false, :default=>:init.to_s
    end

    # serialize plugin must be defined at the bottom of all class
    # method calls.
    # Possible source column data:
    # vdc volume:
    # {:type=>:vdcvol, :account_id=>'a-xxxxx', :snapshot_id=>'snap-xxxxxx'}
    # {:type=>:http, :uri=>'http://localhost/xxx/xxx'}
    plugin :serialization
    serialize_attributes :yaml, :source
    
    def validate
      unless [BOOT_DEV_SAN, BOOT_DEV_LOCAL].member?(self.boot_dev_type)
        errors.add(:boot_dev_type, "Invalid boot dev type: #{self.boot_dev_type}")
      end
      
      unless HostPool::SUPPORTED_ARCH.member?(self.arch)
        errors.add(:arch, "Unsupported arch type: #{self.arch}")
      end
      
      # validate source
      md = self.source
      case md[:type]
      when :http
        errors.add(:source, "Unknown image URI") if md[:uri].nil? || md[:uri].empty?
      when :volume
        errors.add(:source, "Unknown snapshot ID") if VolumeSnapshot[:snapshot_id].nil?#md[:snapshot_id].nil? || md[:snapshot_id].empty?
        errors.add(:source, "Unknown account ID") if Account[:account_id].nil?#md[:account_id].nil? || md[:account_id].empty?
      end
    end

    def to_hash
      super.merge({:source=>self.source.dup, :description=>description.to_s})
    end

    def to_api_document
      to_hash
    end
    
  end
end
