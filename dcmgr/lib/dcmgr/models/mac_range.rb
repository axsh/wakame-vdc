# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Dynamic MAC address range.
  class MacRange < BaseNew
    taggable 'mr'

    def amount_of_available_macs
      leased_count = MacLease.filter("mac_addr >= #{concat_begin}").filter("mac_addr <= #{concat_end}").count
      (concat_end - concat_begin) - leased_count
    end

    def available_macs_left?
      amount_of_available_macs > 0
    end

    # Returns a random unleased address from within the range
    def get_random_available_mac
      return nil unless self.available_macs_left?

      begin
        mac_addr = rand(concat_begin..concat_end)
      end until MacLease.find(:mac_addr=> mac_addr).nil?

      mac_addr
    end

    # These concat methods give you an int representation of the full address. i.e. vendor id and the address combined
    def concat_begin
      (vendor_id * 0x1000000) + range_begin
    end

    def concat_end
      (vendor_id * 0x1000000) + range_end
    end

    def self.exists_in_any_range?(vendor_id, addr)
      !self.filter(:vendor_id => vendor_id).where{"range_begin <= #{addr} && range_end >= #{addr}"}.empty?
    end

  end
end
