# -*- coding: utf-8 -*-

module Dcmgr::Models
  class HostNodeVnet < BaseNew
    include Dcmgr::Logger

    many_to_one :host_node
    many_to_one :network

    def before_validation
      self[:broadcast_addr] = normalize_mac_addr(self[:broadcast_addr])

      super
    end

    def before_destroy
      maclease = MacLease.find(:mac_addr=>self.broadcast_addr.hex)

      if maclease
        maclease.destroy
      else
        logger.info "Warning: Mac address lease for '#{broadcast_addr}' not found in database."
      end

      super
    end

    def validate
      super

      # do not run validation if the row is marked as deleted.
      return true if self.deleted_at

      unless self.broadcast_addr.size == 12 && self.broadcast_addr =~ /^[0-9a-f]{12}$/
        errors.add(:broadcast_addr, "Invalid mac address syntax: #{self.broadcast_addr}")
      end
      if MacLease.find(:mac_addr=>self.broadcast_addr.hex).nil?
        errors.add(:mac_addr, "MAC address is not on the MAC lease database.")
      end
    end

    def pretty_broadcast_addr(delim=':')
      self.broadcast_addr.unpack('A2'*6).join(delim)
    end

    def to_api_document(api_ver=nil)
      h = to_hash
      h.merge!({:broadcast_addr => pretty_broadcast_addr})
    end

    private

    def normalize_mac_addr(str)
      str = str.downcase.gsub(/[^0-9a-f]/, '')
      raise "invalid mac address data: #{str}" if str.size > 12
      # TODO: put more checks on the mac address.
      #       i.e. single 0 to double 00
      str
    end

  end
end
