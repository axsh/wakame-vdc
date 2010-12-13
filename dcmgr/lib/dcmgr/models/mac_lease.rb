# -*- coding: utf-8 -*-

module Dcmgr::Models
  # MAC address lease information
  class MacLease < BaseNew

    inheritable_schema do
      String :mac_addr, :size=>12, :fixed=>true, :null=>false
      
      index :mac_addr, {:unique=>true}
    end
    with_timestamps

    # dynamically assign new MAC address.
    def self.lease(vendor_id='00ff01')
      begin
        m = vendor_id + ("%02x%02x%02x" % [rand(0xff),rand(0xff),rand(0xff)])
      end while self.find(:mac_addr=> m)
      create(:mac_addr=>m)
    end
  end
end
