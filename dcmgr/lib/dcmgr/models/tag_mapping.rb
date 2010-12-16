# -*- coding: utf-8 -*-

module Dcmgr::Models
  class TagMapping < BaseNew
    inheritable_schema do
      Fixnum :tag_id, :null=>false
      String :uuid, :null=>false, :size=>20
      index :tag_id
      index :uuid
    end
    
    many_to_one :tag

  end
end

