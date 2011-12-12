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
      create(:mac_addr=>mac_addr)
    end

    # show default vendor ID for the hypervisor.
    # The virtual interface can be applied any valid MAC address. But using
    # the well known vendor IDs for hypervisor have some benefits. For
    # example, 70-persistent-net.rules issue can be avoided with newer
    # udev release.
    def self.default_vendor_id(hypervisor)
      case hypervisor.to_sym
      when :kvm
        '525400'
      when :lxc
        # LXC is not known with the specific vendor ID. This may be wrong.
        '525400'
      else
        raise "Unknown hypervisor name: #{hypervisor}"
      end
    end
  end
end
