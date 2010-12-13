# -*- coding: utf-8 -*-

module Dcmgr::Models
  # History record table for ArchiveChangedColumn plugin
  class History < BaseNew
    set_dataset(:histories)
    
    inheritable_schema do
      String :uuid, :size=>50, :null=>false
      String :attr, :null=>false
      String :vchar_value, :null=>true
      String :blob_value, :null=>true, :text=>true
      Time  :created_at, :null=>false
      index [:uuid, :created_at]
      index [:uuid, :attr]
    end

    plugin :timestamps
    
  end
end
