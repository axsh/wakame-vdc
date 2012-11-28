# -*- coding: utf-8 -*-

module Dcmgr::Models
  # MAC address lease information
  class MacLease < BaseNew

    # register MAC address.
    # @params [String] 6 or 12 length of HEX value in string.
    def self.lease(mac_addr)
      case mac_addr.size
      when 12
      when 6
        # Assign bottom 6 device ID dynamically.
        vendor_id = mac_addr.dup
        begin
          mac_addr = vendor_id + ("%02x%02x%02x" % [rand(0xff),rand(0xff),rand(0xff)])
        end while self.find(:mac_addr=> mac_addr)
      else
        raise ArgumentError, "Invalid MAC address string: 6 or 12 length of HEX value is needed."
      end
      create(:mac_addr=>mac_addr.hex)
    end

    def self.is_leased?(mac_addr)
      #TODO: Check mac address validity
      !filter(:mac_addr=>mac_addr.hex).empty?
    end

    # Creates a string representation of the hexadecimal mac address
    def pretty_mac_addr(delim=':')
      mac = mac_addr.to_s(16)
      while mac.length < 12
        mac.insert(0,'0')
      end

      mac.scan(/.{2}|.+/).join(delim)
    end

  end
end
