# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Bootable image's metadata catalogs for new Instance.
  class Image < AccountResource
    taggable 'wmi'
    with_timestamps

    STORAGE_SAN_STORE=1
    STORAGE_LOCAL_STORE=2
    
    inheritable_schema do
      Fixnum :storage_type, :null=>false, :default=>STORAGE_SAN_STORE
      String :uri, :null=>false
      String :arch, :null=>false
      String :message
      Fixnum :parent_image_id
    end
    
  end
end
