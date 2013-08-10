# -*- coding: utf-8 -*-

module Dcmgr::Models
  class LocalVolume < BaseNew
    unrestrict_primary_key
    
    many_to_one :instance
    one_to_one :volume, :key=>:id

    def host_node
      self.instance.host_node
    end
  end
end
