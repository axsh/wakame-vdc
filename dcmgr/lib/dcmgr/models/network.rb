# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  # IP network definitions.
  class Network < AccountResource
    taggable 'nw'

    module IpLeaseMethods
      def add_reserved(ipaddr, description=nil)
        model.create(:network_id=>model_object.id,
                     :ipv4=>ipaddr,
                     :alloc_type=>IpLease::TYPE_RESERVED,
                     :description=>description)
      end

      def delete_reserved(ipaddr)
        model.filter(:network_id=>model_object.id,
                     :alloc_type=>IpLease::TYPE_RESERVED,
                     :ipv4=>ipaddr).delete
      end
    end
    one_to_many :ip_lease, :extend=>IpLeaseMethods
    
    many_to_one :nat_network, :key => :nat_network_id, :class => self
    one_to_many :inside_networks, :key => :nat_network_id, :class => self

    one_to_many :dhcp_range
    many_to_one :physical_network

    def network_service
      NetworkService.dataset.join_table(:left, :network_vifs, :id => :network_vif_id).where(:network_id => self.id).select_all(:network_services)
    end

    def add_service_vif(ipv4)
      # Choose vendor ID of mac address.
      vendor_id = if Dcmgr.conf.mac_address_vendor_id
                    Dcmgr.conf.mac_address_vendor_id
                  else
                    # M::MacLease.default_vendor_id(self.instance_spec.hypervisor)
                    MacLease.default_vendor_id('kvm')
                  end
      m = MacLease.lease(vendor_id)

      vif_data = {
        :network_id => self.id,
        :mac_addr => m.mac_addr,
      }

      vif = NetworkVif.new(vif_data)
      vif.save
      ip_lease = self.ip_lease_dataset.add_reserved(ipv4)
      ip_lease.network_vif_id = vif.id
      ip_lease.save
      vif
    end

    def nat_network
      Network.find(:id => self.nat_network_id)
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
      leases = self.ip_lease_dataset.where(:ipv4 => ipaddr.to_s)

      return nil if leases.empty?
      leases.first
    end

    # register reserved IP address in this network
    def add_reserved(ipaddr)
      raise "Out of subnet range: #{ipaddr} to #{self.ipv4_ipaddress}/#{self.prefix}" if !self.include?(ipaddr)
      add_ip_lease(:ipv4=>ipaddr.to_s, :type=>IpLease::TYPE_RESERVED)
    end

    def available_ip_nums
      self.ipv4_ipaddress.hosts.size - self.ip_lease_dataset.count
    end

    def ipv4_u32_dynamic_range_array
      ary=[]
      dhcp_range_dataset.each { |r|
        ary += (r.range_begin.to_u32 .. r.range_end.to_u32).to_a
      }
      ary
    end

    def add_ipv4_dynamic_range(range_begin, range_end)
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
      
      self.add_dhcp_range(:range_begin=>range_begin.to_s, :range_end=>range_end.to_s)
      
      self
    end

    def del_ipv4_dynamic_range(range_begin, range_end)
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

    #
    # Sequel methods:
    #

    def before_validation
      self.link_interface ||= "br-#{self[:uuid]}"
      super
    end

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
    end

    def to_hash
      h = super
      h.merge!({
                 :bandwidth_mark=>self[:id],
                 :description=>description.to_s,
                 :network_services => [],
               })
      if self.physical_network
        h[:physical_network] = self.physical_network.to_hash
      end
     
      self.network_service.each { |service|
        h[:network_services] << service.to_hash
      }

      h
    end

    def to_api_document
      to_hash.merge(:id=>self.canonical_uuid)
    end

    def before_destroy
      #Make sure no other networks are natted to this one
      Network.filter(:nat_network_id => self[:id]).each { |n|
        n.nat_network_id = nil
        n.save
      }
      
      #Delete all reserved ipleases in this network
      self.ip_lease_dataset.filter(:alloc_type => IpLease::TYPE_RESERVED).each { |i|
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
