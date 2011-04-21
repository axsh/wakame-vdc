# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class InstanceNic < BaseNew
    taggable 'vif'

    inheritable_schema do
      Fixnum :instance_id, :null=>false
      Fixnum :network_id, :null=>false
      Fixnum :nat_network_id
      String :mac_addr, :null=>false, :size=>12
      
      index :mac_addr
    end
    with_timestamps

    many_to_one :instance
    many_to_one :nat_network, :key => :nat_network_id, :class => Network
    many_to_one :network
    one_to_many :ip, :class=>IpLease

    def to_hash
      h = values.dup.merge(super)
      h.delete(:instance_id)
      h
    end

    def before_validation
      newlease=nil
      m = self[:mac_addr] = normalize_mac_addr(self[:mac_addr])
      if m
        if m.size == 6
          newlease = MacLease.lease(m)
        else
          MacLease.create(:mac_addr=>m)
        end
      else
        newlease = MacLease.lease()
      end
      self[:mac_addr] = newlease.mac_addr if newlease
      
      super
    end

    def before_destroy
      MacLease.find(:mac_addr=>self.mac_addr).destroy
      ip_dataset.destroy
      super
    end

    def validate
      super

      unless self.mac_addr.size == 12 && self.mac_addr =~ /^[0-9a-f]{12}$/
        errors.add(:mac_addr, "Invalid mac address syntax: #{self.mac_addr}")
      end
    end

    def pretty_mac_addr(delim=':')
      self.mac_addr.unpack('A2'*6).join(delim)
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
