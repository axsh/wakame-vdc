# -*- coding: utf-8 -*-

module Dcmgr::Models
  class LocalVolume < BaseNew
    unrestrict_primary_key
    
    many_to_one :host_node
    one_to_one :volume, :key=>:id
  end
end
