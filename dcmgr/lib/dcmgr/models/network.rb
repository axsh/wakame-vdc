# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP network definitions.
  class Network < AccountResource
    taggable 'nw'
    accept_service_type

    include Dcmgr::Constants::Network

    module NetworkVifIpLeaseMethods
      def add_reserved(ipaddr)
        model.create(:network_id => model_object.id,
                     :ipv4=>IPAddress::IPv4.new(ipaddr).to_i,
                     :alloc_type=> NetworkVifIpLease::TYPE_RESERVED,
                     :description=>ipaddr)
      end

      def delete_reserved(ipaddr)
        model.filter(:network_id=>model_object.id,
                     :alloc_type=>NetworkVifIpLease::TYPE_RESERVED,
                     :ipv4=>IPAddress::IPv4.new(ipaddr).to_i).destroy
      end
    end

    one_to_many :network_vif
    one_to_many :network_vif_ip_lease, :class=>NetworkVifIpLease, :extend=>NetworkVifIpLeaseMethods

    many_to_one :nat_network, :key => :nat_network_id, :class => self
    one_to_many :inside_networks, :key => :nat_network_id, :class => self

    one_to_many :dhcp_range
    many_to_one :dc_network

    def network_service(params = {})
      params[:network_id] = self.id
      NetworkService.dataset.join_table(:left, :network_vifs, :id => :network_vif_id).where(params).select_all(:network_services)
    end

    def network_routes(params = {})
      params[:network_id] = self.id
      NetworkRoute.dataset.join_table(:left, :network_vifs,
                                      {:network_vifs__id => :network_routes__inner_vif_id} |
                                      {:network_vifs__id => :network_routes__outer_vif_id}).where(params).select_all(:network_routes)
    end

    def add_service_vif(ipv4)
      ip_lease = self.find_ip_lease(ipv4)

      if ip_lease
        # Verify vif is service vif.
        return ip_lease.network_vif
      end

      m = MacLease.lease(Dcmgr.conf.mac_address_vendor_id)

      vif_data = {
        :account_id => self.account_id,
        :network_id => self.id,
        :mac_addr => m.pretty_mac_addr(''),
      }

      vif = NetworkVif.new(vif_data)
      vif.save
      ip_lease = self.network_vif_ip_lease_dataset.add_reserved(ipv4)
      ip_lease.network_vif_id = vif.id
      ip_lease.save_changes
      vif
    end

    def nat_network
      Network.find(:id => self.nat_network_id)
    end

    def exists_in_dhcp_range?(ipaddr)
      ipaddr = ipaddr.is_a?(IPAddress::IPv4) ? ipaddr : IPAddress::IPv4.new(ipaddr)

      !self.dhcp_range_dataset.where{"range_begin <= #{ipaddr.to_i} && range_end >= #{ipaddr.to_i}"}.empty?
    end

    def ipv4_ipaddress
      IPAddress::IPv4.new("#{self.ipv4_network}/#{self.prefix}").network
    end

    def ipv4_gw_ipaddress
      return nil if self.ipv4_gw.nil?
      IPAddress::IPv4.new("#{self.ipv4_gw}/#{self.prefix}")
    end

    # check if the given IP addess is in the range of this network.
    # @param [String] ipaddr IP address
    def include?(ipaddr)
      ipaddr = ipaddr.is_a?(IPAddress::IPv4) ? ipaddr : IPAddress::IPv4.new(ipaddr)
      self.ipv4_ipaddress.network.include?(ipaddr)
    end

    # return IpLease for IP address in this network
    # @param [String] ipaddr IP address
    def find_ip_lease(ipaddr)
      ipaddr = ipaddr.is_a?(IPAddress::IPv4) ? ipaddr : IPAddress::IPv4.new(ipaddr)
      leases = self.network_vif_ip_lease_dataset.where(:ipv4 => ipaddr.to_i).alives
      return nil if leases.empty?
      leases.first
    end

    # register reserved IP address in this network
    def add_reserved(ipaddr)
      raise "Out of subnet range: #{ipaddr} to #{self.ipv4_ipaddress}/#{self.prefix}" if !self.include?(ipaddr)
      add_ip_lease(:ipv4=>ipaddr.to_s, :type=>IpLease::TYPE_RESERVED)
    end

    def available_ip_nums
      self.ipv4_ipaddress.hosts.size - self.network_vif_ip_lease_dataset.count
    end

    def allocated_ip_nums
      self.network_vif_ip_lease_dataset.exclude(:alloc_type=>NetworkVifIpLease::TYPE_RESERVED).alives.count
    end

    def ipv4_u32_dynamic_range_array
      ary=[]
      dhcp_range_dataset.each { |r|
        ary += (r.range_begin.to_u32 .. r.range_end.to_u32).to_a
      }
      ary
    end

    def add_ipv4_dynamic_range(range_begin, range_end)
      range_begin = IPAddress::IPv4.new("#{range_begin}/#{self[:prefix]}")
      range_end = IPAddress::IPv4.new("#{range_end}/#{self[:prefix]}")
      test_inclusion(*validate_range_args(range_begin, range_end)) { |range, op|
         case op
         when :coverbegin
           range.range_end = range_begin
         when :coverend
           range.range_begin = range_end
         when :inccur
           range.destroy
         end
         range.save_changes
      }

      self.add_dhcp_range(:range_begin=>range_begin, :range_end=>range_end)

      self
    end

    def del_ipv4_dynamic_range(range_begin, range_end)
      range_begin = IPAddress::IPv4.new("#{range_begin}/#{self[:prefix]}")
      range_end = IPAddress::IPv4.new("#{range_end}/#{self[:prefix]}")
      test_inclusion(*validate_range_args(range_begin, range_end)) { |range, op|
        case op
        when :coverbegin
          range.range_end = range_begin
        when :coverend
          range.range_begin = range_end
        when :inccur
          range.destroy
        when :incnew
          t = range.range_end
          range.range_end = range_begin
          self.add_dhcp_range(:range_begin=>range_end, :range_end=>t)
        end
        range.save_changes
      }

      self
    end

    # To check the IP address that can not be used.
    # TODO add a check of network services
    def reserved_ip?(ip)
      raise ArgumentError unless ip.is_a?(::IPAddress::IPv4)
      ipaddr = ip.to_s

      if self.ipv4_ipaddress.to_s == ipaddr ||
          self.ipv4_ipaddress.broadcast.to_s == ipaddr ||
          self[:ipv4_gw] == ipaddr ||
          self[:dns_server] == ipaddr ||
          self[:dhcp_server] == ipaddr ||
          self[:metadata_server] == ipaddr
        return true
      else
        return false
      end
    end

    #
    # Sequel methods:
    #

    def validate
      super

      unless (1..31).include?(self.prefix.to_i)
        errors.add(:prefix, "prefix must be 1-31: #{self.prefix}")
      end

      network_addr = begin
                       IPAddress::IPv4.new("#{self.ipv4_network}/#{self.prefix}").network
                     rescue => e
                       errors.add(:ipv4_network, "Invalid IP address syntax: #{self.ipv4_network}")
                     end
      # validate ipv4 syntax
      if self.ipv4_gw
        begin
          if !network_addr.include?(IPAddress::IPv4.new("#{self.ipv4_gw}"))
            errors.add(:ipv4_gw, "Out of network address range: #{network_addr.to_s}")
          end
        rescue => e
          errors.add(:ipv4_gw, "Invalid IP address syntax: #{self.ipv4_gw}")
        end
      end

      if self.dhcp_server
        begin
          if !network_addr.include?(IPAddress::IPv4.new("#{self.dhcp_server}"))
            errors.add(:dhcp_server, "Out of network address range: #{network_addr.to_s}")
          end
        rescue => e
          errors.add(:dhcp_server, "Invalid IP address syntax: #{self.dhcp_server}")
        end
      end

      if self.network_mode.nil?
        errors.add(:network_mode, "Unset network mode")
      elsif !NETWORK_MODES.member?(self.network_mode)
        errors.add(:network_mode, "Unknown network mode: #{self.network_mode}")
      end
    end

    def to_hash
      h = super
      h.merge!({
                 :bandwidth_mark=>self[:id],
                 :description=>description.to_s,
                 :network_services => [],
               })
      if self.dc_network
        h[:dc_network] = self.dc_network.to_hash
      end

      self.network_service.each { |service|
        h[:network_services] << service.to_hash
      }

      h
    end

    def to_netfilter_document
      {
        :uuid => self.canonical_uuid,
        :ipv4_gw => self.ipv4_gw,
        :prefix => self.prefix,
        :dns_server => self.dns_server,
        :dhcp_server => self.dhcp_server,
        :metadata_server => self.metadata_server,
        :metadata_server_port => self.metadata_server_port,
        :network_mode => self.network_mode
      }
    end

    def before_destroy
      #Make sure no other networks are natted to this one
      Network.filter(:nat_network_id => self[:id]).each { |n|
        n.nat_network_id = nil
        n.save
      }

      #Delete all reserved ipleases in this network
      self.network_vif_ip_lease_dataset.filter(:alloc_type => NetworkVifIpLease::TYPE_RESERVED).each { |i|
        i.destroy
      }

      super
    end

    private
    def validate_range_args(range_begin, range_end)
      if range_begin.is_a?(IPAddress::IPv4)
        raise "Different prefix length: range_begin" if range_begin.prefix != self.prefix
      else
        range_begin = IPAddress::IPv4.new("#{range_begin}/#{self.prefix}")
      end
      if range_end.is_a?(IPAddress::IPv4)
        raise "Different prefix length: range_end" if range_end.prefix != self.prefix
      else
        range_end = IPAddress::IPv4.new("#{range_end}/#{self.prefix}")
      end
      if !(self.ipv4_ipaddress.include?(range_begin) && self.ipv4_ipaddress.include?(range_end))
        raise "Given address range is out of the subnet: #{self.ipv4_ipaddress} #{range_begin}-#{range_end}"
      end
      if range_begin > range_end
        t = range_begin
        range_begin = range_end
        range_end = t
      end
      [range_begin, range_end]
    end


    def test_inclusion(range_begin, range_end, &blk)
      dhcp_range_dataset.each { |r|
        op = :outrange
        if r.range_begin < range_begin && r.range_end > range_begin
          # range_begin is in the range.
          if r.range_end < range_end
            op = :coverbegin
          else
            # new range is included in current range.
            op = :incnew
          end
        elsif r.range_begin < range_end && r.range_end > range_end
          # range_end is in the range.
          if r.range_begin > range_begin
            op = :coverend
          end
        elsif r.range_begin >= range_begin && r.range_end <= range_end
          # current range is included in new range.
          op = :inccur
        end
        blk.call(r, op)
      }
    end
  end
end
