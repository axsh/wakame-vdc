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

    # Converts a mac address in string format
    # to an interger vendor id and address
    #TODO: move to helper
    def self.string_to_ints(addr_str)
      case addr_str.size
      when 6
        [Dcmgr::Configurations.dcmgr.mac_address_vendor_id.hex, addr_str.hex]
      when 12
        [
          addr_str[0,6].hex,
          addr_str[6,12].hex
        ]
      end
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
