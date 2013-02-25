# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetworkRoute < BaseNew
    
    many_to_one :outer_network, :key => :outer_network_id, :class => Network
    many_to_one :inner_network, :key => :inner_network_id, :class => Network

    many_to_one :outer_vif, :key => :outer_vif_id, :class => NetworkVif
    many_to_one :inner_vif, :key => :inner_vif_id, :class => NetworkVif

    subset(:alives, {:deleted_at => nil})

    def outer_ipv4
      IPAddress::IPv4::parse_u32(self[:outer_ipv4])
    end

    def inner_ipv4
      IPAddress::IPv4::parse_u32(self[:inner_ipv4])
    end

    def outer_ipv4_s
      IPAddress::IPv4::parse_u32(self[:outer_ipv4]).to_s
    end

    def inner_ipv4_s
      IPAddress::IPv4::parse_u32(self[:inner_ipv4]).to_s
    end

    def outer_ipv4_i
      self[:outer_ipv4]
    end

    def inner_ipv4_i
      self[:inner_ipv4]
    end

    #
    # Sequel methods:
    #

    def validate
      [:inner, :outer].each { |arg|
        if self["#{arg}_ipv4".to_sym] && !self.send("#{arg}_network").include?(self.send("#{arg}_ipv4"))
          errors.add("#{arg}_ipv4".to_sym, "#{arg} IP address out of range: #{self.send("#{arg}_ipv4_s".to_sym)}")
        end
      }

      super
    end

    def around_create
      Sequel.transaction([NetworkRoute.db, NetworkVifIpLease.db, IpLease.db]) {
        if @create_options.nil?
          super
          next
        end

        [:inner, :outer].each { |arg|
          if @create_options["lease_#{arg}_ipv4".to_sym]
            raise("Cannot pass #{arg} IPv4 address argument when leasing address") if self["#{arg}_ipv4".to_sym]

            vif = @create_options["lease_#{arg}_from_vif".to_sym]
            ip_lease = vif.lease_ipv4({:multiple => true})

            raise("Could not lease #{arg} IPv4 address") if ip_lease.nil?
            self["#{arg}_ipv4".to_sym] = ip_lease.ipv4_i
          end
        }

        # Validate again to ensure the new values pass the sanity test.
        self.validate
        super
      }
    end

    #
    # Private methods
    #
    private

    def initialize_set(values)
      @create_options = values.delete(:create_options)
      super
    end

  end
end
