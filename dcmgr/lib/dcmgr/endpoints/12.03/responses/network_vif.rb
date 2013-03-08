# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network_vif_monitor'

module Dcmgr::Endpoints::V1203::Responses
  class NetworkVif < Dcmgr::Endpoints::ResponseGenerator
    def initialize(network_vif)
      raise ArgumentError if !network_vif.is_a?(Dcmgr::Models::NetworkVif)
      @network_vif = network_vif
    end

    def generate()
      @network_vif.instance_exec {
        { :id=>canonical_uuid,
          :uuid=>canonical_uuid,
          :ipv4_address => self.direct_ip_lease.first.nil? ? nil : self.direct_ip_lease.first.ipv4,
          :nat_ipv4_address => self.nat_ip_lease.first.nil? ? nil : self.nat_ip_lease.first.ipv4,
          :network_id => self.network.nil? ? nil : self.network.canonical_uuid,
          :instance_id => self.instance.nil? ? nil : self.instance.canonical_uuid,
          :security_groups => self.security_groups.map{|sg| sg.canonical_uuid },
          :mac_addr => self.pretty_mac_addr,
          :network_monitors => network_vif_monitors_dataset.alives.all.map {|m|
            NetworkVifMonitor.new(m).generate
          },
          :ip_leases => self.ip_leases.map { |lease|
            NetworkVifIpLease.new(lease).generate
          },
        }
      }
    end
  end

  class NetworkVifCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        NetworkVif.new(i).generate
      }
    end
  end

  class NetworkVifIpLease < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::NetworkVifIpLease)
      @object = object
    end

    def generate()
      @object.instance_exec {
        { :ipv4 => self.ipv4_s,
          :network_id => self.network.canonical_uuid,
          :ip_handle => self.ip_handle.nil? ? nil : {
            :id => self.ip_handle.canonical_uuid,
            :display_name => self.ip_handle.display_name,
          }
        }
      }
    end
  end

end
