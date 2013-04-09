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
    one_to_many(:ip_leases, :class=>NetworkVifIpLease, :read_only=>true) do |ds|
      ds.alives
    end
    one_to_many(:direct_ip_lease, :class=>NetworkVifIpLease, :read_only=>true) do |ds|
      ds.where(:network_id=>self.network_id).alives
    end
    one_to_many(:nat_ip_lease, :class=>NetworkVifIpLease, :read_only=>true) do |ds|
      ds.where(:network_id=>self.nat_network_id).alives
    end

    one_to_many :network_routes, :class=>NetworkRoute do |ds|
      ds = NetworkRoute.dataset.join_with_ip_leases.where(:network_vif_ip_leases__network_vif_id => self.id)
      ds.select_all(:network_routes).alives
    end

    subset(:alives, {:deleted_at => nil})

    many_to_one :instance
    one_to_many :network_services
    one_to_many :network_vif_monitors

    dataset_module {
      def join_with_services
        self.join_table(:left, :network_services, :network_vifs__id => :network_services__network_vif_id)
      end

      def join_with_routes
        self.join_table(:left, :network_routes,
                        {:network_vifs__id => :network_routes__inner_vif_id} |
                        {:network_vifs__id => :network_routes__outer_vif_id})
      end

      def join_with_outer_routes
        self.join_table(:left, :network_routes, :network_vifs__id => :network_routes__outer_vif_id)
      end

      def join_with_inner_routes
        self.join_table(:left, :network_routes, :network_vifs__id => :network_routes__inner_vif_id)
      end

      def where_with_services(param)
        join_with_services.where(param).select_all(:networks)
      end

      def where_with_routes(param)
        join_with_routes.where(param).select_all(:networks)
      end
    }

    def network_vifs_with_service(params = {})
      params[:network_id] = self.id
      NetworkVif.dataset.join_table(:left, :network_services,
                                    :network_vifs__id => :network_services__network_vif_id
                                    ).where(params).select_all(:network_vifs)
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

    # Updated IP lease function
    def lease_ipv4(options = {})
      network = self.network

      return nil if network.nil?
      return nil if options[:multiple] != true && !self.direct_ip_lease.empty?

      return IpLease.lease(self, network)
    end

    # return IpLease for IP address in this network vif
    # @param [String] ipaddr IP address
    def find_ip_lease(ipaddr)
      ipaddr = ipaddr.is_a?(IPAddress::IPv4) ? ipaddr : IPAddress::IPv4.new(ipaddr)
      ip_dataset.where(:ipv4 => ipaddr.to_i).alives.first
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
      maclease = MacLease.find(:mac_addr=>self.mac_addr.hex)
      if maclease
        maclease.destroy
      else
        logger.info "Warning: Mac address lease for '#{self.mac_addr}' not found in database."
      end
      release_ip_lease
      if self.instance.service_type == Dcmgr::Constants::LoadBalancer::SERVICE_TYPE
        groups = self.security_groups
        self.remove_all_security_groups
        groups.each {|g| g.destroy}
      else
        self.remove_all_security_groups
      end
      self.network_routes.each {|i| i.destroy }
      self.network_services.each {|i| i.destroy }
      self.network_vif_monitors.each {|i| i.destroy }
      super
    end

    def validate
      super

      # do not run validation if the row is marked as deleted.
      return true if self.deleted_at

      unless self.mac_addr.size == 12 && self.mac_addr =~ /^[0-9a-f]{12}$/
        errors.add(:mac_addr, "Invalid mac address syntax: #{self.mac_addr}")
      end
      if MacLease.find(:mac_addr=>self.mac_addr.hex).nil?
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

    def add_ip_lease(options)
      network = self.network
      lease = options[:ip_lease]

      return nil if options[:allow_multiple] != true && !self.direct_ip_lease.empty?

      return nil unless lease.is_a?(NetworkVifIpLease)
      return nil unless lease.network_vif.nil?

      if options[:attach_network] == true && network == nil
        self.network = network
        self.save_changes
      end

      return nil unless lease.network == network
      
      lease.attach_vif(self)
      lease
    end

    def remove_ip_lease(options)
      lease = options[:ip_lease]

      return nil unless lease.is_a?(NetworkVifIpLease)
      return nil unless lease.network_vif == self

      if lease.ip_handle
        lease.detach_vif
      else
        lease.destroy
      end
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
