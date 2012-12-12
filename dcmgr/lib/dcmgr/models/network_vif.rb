# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class NetworkVif < AccountResource
    include Dcmgr::Logger
    taggable 'vif'

    many_to_one :network
    many_to_many :security_groups, :join_table=>:network_vif_security_groups
    # To be moved to proper instance_nic.

    many_to_one :nat_network, :key => :nat_network_id, :class => Network
    one_to_many :ip, :class=>NetworkVifIpLease
    one_to_many(:direct_ip_lease, :class=>NetworkVifIpLease, :read_only=>true) do |ds|
      ds.where(:network_id=>self.network_id).alives
    end
    one_to_many(:nat_ip_lease, :class=>NetworkVifIpLease, :read_only=>true) do |ds|
      ds.where(:network_id=>self.nat_network_id).alives
    end

    subset(:alives, {:deleted_at => nil})

    many_to_one :instance
    one_to_many :network_services
    one_to_many :network_vif_monitors

    def add_security_groups_by_id(group_ids)
      group_ids = [group_ids] unless group_ids.respond_to?(:each)
      group_ids.each { |group_id|
        group = Dcmgr::Models::SecurityGroup[group_id]
        raise NetworkSchedulingError, "Security group: #{group_id} doesn't exit" if group.nil?
        self.add_security_group(group)
      }
    end

    def to_hash
      hash = super
      hash.merge!({ :address => self.direct_ip_lease.first.nil? ? nil : self.direct_ip_lease.first.ipv4,
                    :nat_ip_lease => self.nat_ip_lease.first.nil? ? nil : self.nat_ip_lease.first.ipv4,
                    :instance_uuid => nil,
                    :host_node_id => nil,
                    :network_id => self.network_id,
                    :network => self.network.nil? ? nil : self.network.to_hash,
                    :security_groups => self.security_groups.map {|n| n.canonical_uuid },
                    :network_vif_monitors => self.network_vif_monitors_dataset.alives.map {|n| n.to_hash },
                  })

      if self.instance
        hash.merge!({ :instance_uuid => self.instance.canonical_uuid,
                      :host_node_id => self.instance.host_node.nil? ? nil : self.instance.host_node.node_id,
                    })
      end

      hash
    end

    # Hash used for including with e.g. network service hash without
    # including excessive or namespace colliding keys.
    def to_hash_flat
      hash = {
        :network_vif_uuid => self.canonical_uuid,
        :network_id => self.network_id,
        :address => self.direct_ip_lease.first.nil? ? nil : self.direct_ip_lease.first.ipv4,
        :nat_ip_lease => self.nat_ip_lease.first.nil? ? nil : self.nat_ip_lease.first.ipv4,
        :mac_addr => self.pretty_mac_addr,
        :instance_uuid => self.instance.nil? ? nil : self.instance.canonical_uuid,
      }
    end

    def to_netfilter_document
      {
        :uuid => self.canonical_uuid,
        :mac_addr => self.mac_addr,
        :address => self.direct_ip_lease.first.nil? ? nil : self.direct_ip_lease.first.ipv4,
        :nat_ip_lease => self.nat_ip_lease.first.nil? ? nil : self.nat_ip_lease.first.ipv4,
        :instance_uuid => self.instance.nil? ? nil : self.instance.canonical_uuid,
        :network_id => self.network.nil? ? nil : self.network.canonical_uuid,
        :security_groups => self.security_groups.map {|n| n.canonical_uuid }
      }
    end

    def lease_ip_lease
      network = self.network
      if self.network && self.direct_ip_lease.empty?
        IpLease.lease(self, network)
      end
      nat_network = self.nat_network
      if nat_network && self.nat_ip_lease.empty?
        IpLease.lease(self, nat_network)
      end
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
      self[:mac_addr] = normalize_mac_addr(self[:mac_addr]) if self.mac_addr

      # set maximum index number if the nic has no index value and
      # is attached to instance.
      if self.instance_id && self.device_index.nil?
        max_idx = self.class.alives.filter(:instance_id=>self.instance_id).max(:device_index)
        self.device_index = max_idx.nil? ? 0 : (max_idx + 1)
      end

      super
    end

    def before_destroy
      maclease = MacLease.find(:mac_addr=>self.mac_addr.hex)
      if maclease
        maclease.destroy
      else
        logger.info "Warning: Mac address lease for '#{self.mac_addr}' not found in database."
      end
      release_ip_lease
      self.remove_all_security_groups
      self.remove_all_security_groups
      self.network_services.each {|i| i.destroy }
      self.network_vif_monitors.each {|i| i.destroy }
      super
    end

    def validate
      super

      # do not run validation if the row is marked as deleted.
      return true if self.deleted_at

      if self.mac_addr
        unless self.mac_addr.size == 12 && self.mac_addr =~ /^[0-9a-f]{12}$/
          errors.add(:mac_addr, "Invalid mac address syntax: #{self.mac_addr}")
        end
        if MacLease.find(:mac_addr=>self.mac_addr.hex).nil?
          errors.add(:mac_addr, "MAC address is not on the MAC lease database.")
        end
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
      detach_from_network if self.network

      self.network = network
      self.save_changes
      lease_ip_lease
    end

    def detach_from_network
      self.network = nil
      self.save_changes
      release_ip_lease
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
