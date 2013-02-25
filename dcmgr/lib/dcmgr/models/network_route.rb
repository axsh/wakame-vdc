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

        # Verify IP address.
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
          options = @create_options[arg]
          current_vif = self.send("#{arg}_vif")
          current_network = self.send("#{arg}_network")

          if options[:find_service]
            params = {:network_services__name => options[:find_service]}
            params[:network_vifs__id] = current_vif.id if current_vif

            vifs = current_network.network_vifs_with_service(params)
            raise("Could not find network service for supplied network vif.") if vifs.empty?

            if current_vif.nil?
              current_vif = vifs.first
              self["#{arg}_vif_id".to_sym] = current_vif.id
            end
          end

          if options[:lease_ipv4]
            raise("Cannot pass #{arg} IPv4 address argument when leasing address") if self["#{arg}_ipv4".to_sym]

            ip_lease = current_vif.lease_ipv4({:multiple => true})
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
