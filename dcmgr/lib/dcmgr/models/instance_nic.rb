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
      Time   :deleted_at

      index :mac_addr
      index :deleted_at
    end
    with_timestamps

    many_to_one :instance
    many_to_one :nat_network, :key => :nat_network_id, :class => Network
    many_to_one :network
    one_to_many :ip, :class=>IpLease
    one_to_many(:direct_ip_lease, :class=>IpLease, :read_only=>true) do |ds|
      ds.where(:network_id=>self.network_id)
    end
    one_to_many(:nat_ip_lease, :class=>IpLease, :read_only=>true) do |ds|
      ds.where(:network_id=>self.nat_network_id)
    end

    def to_hash
      h = values.dup.merge(super)
      h.delete(:instance_id)
      h
    end

    def release_ip_lease
      ip_dataset.destroy
    end

    #Override the delete method to keep the row and just mark it as deleted
    def delete
      self.deleted_at ||= Time.now
      self.save
    end

    def before_validation
      self[:mac_addr] = normalize_mac_addr(self[:mac_addr])
      super
    end

    def before_destroy
      maclease = MacLease.find(:mac_addr=>self.mac_addr)
      maclease.destroy if maclease
      release_ip_lease
      super
    end

    def validate
      super

      # do not run validation if the row is maked as deleted.
      return true if self.deleted_at

      unless self.mac_addr.size == 12 && self.mac_addr =~ /^[0-9a-f]{12}$/
        errors.add(:mac_addr, "Invalid mac address syntax: #{self.mac_addr}")
      end
      if MacLease.find(:mac_addr=>self.mac_addr).nil?
        errors.add(:mac_addr, "MAC address is not on the MAC lease database.")
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
