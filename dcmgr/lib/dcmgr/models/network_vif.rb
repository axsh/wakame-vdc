# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class NetworkVif < BaseNew
    taggable 'vif'

    # Remove? reverse lookup.
    many_to_one :instance, :join_table=>:instance_nic_join
    one_to_one  :network_port, :read_only=>true
    alias :port :network_port

    many_to_one :nat_network, :key => :nat_network_id, :class => Network
    one_to_many :ip, :class=>IpLease
    one_to_many(:direct_ip_lease, :class=>IpLease, :read_only=>true) do |ds|
      ds.where(:network_id=>self.network_id)
    end
    one_to_many(:nat_ip_lease, :class=>IpLease, :read_only=>true) do |ds|
      ds.where(:network_id=>self.nat_network_id)
    end

    subset(:alives, {:deleted_at => nil})

    def network
      return nil if network_port.nil?
      network_port.network
    end

    def network_id
      return nil if network_port.nil?
      network_port.network_id
    end

    def to_api_document
      hash = super
      hash.delete(instance_id)
      hash.merge({:network_id => network_id})
      hash
    end

    def to_hash
      hash = super
      hash.merge({:network_id => network_id})
      hash
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

      # set maximum index number if the nic has no index value and
      # is attached to instance.
      if self.instance_id && self.device_index.nil?
        max_idx = self.class.alives.filter(:instance_id=>self.instance_id).max(:device_index)
        self.device_index = max_idx.nil? ? 0 : (max_idx + 1)
      end
      
      super
    end

    def before_destroy
      maclease = MacLease.find(:mac_addr=>self.mac_addr)
      maclease.destroy if maclease
      release_ip_lease

      network_port_dataset.destroy
      super
    end

    def validate
      super

      # do not run validation if the row is marked as deleted.
      return true if self.deleted_at

      unless self.mac_addr.size == 12 && self.mac_addr =~ /^[0-9a-f]{12}$/
        errors.add(:mac_addr, "Invalid mac address syntax: #{self.mac_addr}")
      end
      if MacLease.find(:mac_addr=>self.mac_addr).nil?
        errors.add(:mac_addr, "MAC address is not on the MAC lease database.")
      end

      # find duplicate device index.
      if self.instance_id
        idx = self.class.alives.filter(:instance_id=>self.instance_id).select(:device_index).all
        if idx.uniq.size != idx.size
          errors.add(:device_index, "Duplicate device index.")
        end
      end
    end

    def pretty_mac_addr(delim=':')
      self.mac_addr.unpack('A2'*6).join(delim)
    end

    def fqdn_hostname
      raise "Instance is not associated: #{self.canonical_uuid}" if self.instance.nil?
      raise "Network is not associated: #{self.canonical_uuid}" if self.network.nil?
      sprintf("%s.%s.%s", self.instance.hostname, self.instance.account.uuid, self.network.domain_name)
    end

    def nat_fqdn_hostname
      raise "Instance is not associated: #{self.canonical_uuid}" if self.instance.nil?
      raise "Network is not associated: #{self.canonical_uuid}" if self.network.nil?
      sprintf("%s.%s.%s", self.instance.hostname, self.instance.account.uuid, self.nat_network.domain_name)
    end

    def attach_to_network(network)
      # Verify no network is not set.
      NetworkPort.lock!

      savedata = {
        :network_id => network.id,
        :network_vif_id => self.id
      }
      port = NetworkPort.create(savedata)
    end

    def detach_from_network
      network_port_dataset.destroy
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
