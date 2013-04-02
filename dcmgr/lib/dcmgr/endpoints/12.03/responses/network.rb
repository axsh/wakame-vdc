# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/dc_network'

module Dcmgr::Endpoints::V1203::Responses
  class Network < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::Network)
      @object = object
    end

    def generate()
      api_hash = @object.to_hash
      api_hash.merge!({ :id => @object.canonical_uuid,
                        :dc_network => @object.dc_network ? DcNetwork.new(@object.dc_network).generate : nil,
                        :nat_network_id => @object.nat_network ? @object.nat_network.canonical_uuid : nil,
                        :network_services => [],
                      })
      [:dc_network_id, :gateway_network_id].each { |k| api_hash.delete(k) }

      @object.network_service.each { |service|
        api_hash[:network_services] << NetworkService.new(service).generate
      }

      api_hash
    end
  end

  class NetworkCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        Network.new(i).generate
      }
    end
  end

  class NetworkRoute < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::NetworkRoute)
      @object = object
    end

    def generate()
      outer_lease = @object.outer_lease
      inner_lease = @object.inner_lease

      hash = {
        :route_type => @object.route_type,
        :outer => {
          :network_id => outer_lease.network ? outer_lease.network.canonical_uuid : nil,
          :network_vif_id => outer_lease.network_vif ? outer_lease.network_vif.canonical_uuid : nil,
          :ipv4 => outer_lease.ipv4_s,
        },
        :inner => {
          :network_id => inner_lease.network ? inner_lease.network.canonical_uuid : nil,
          :network_vif_id => inner_lease.network_vif ? inner_lease.network_vif.canonical_uuid : nil,
          :ipv4 => inner_lease.ipv4_s,
        },
      }
    end
  end

  class NetworkRouteCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        NetworkRoute.new(i).generate
      }
    end
  end

  class NetworkService < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::NetworkService)
      @object = object
    end

    def generate()
      vif = @object.network_vif

      hash = {
        :name => @object.name,
        :network_id => vif.network.canonical_uuid,
        :network_vif_id => vif.canonical_uuid,
        :address => vif.direct_ip_lease.first ? vif.direct_ip_lease.first.ipv4 : nil,
        :mac_addr => vif.pretty_mac_addr,
        :incoming_port => @object.incoming_port,
        :outgoing_port => @object.outgoing_port,
        :created_at => @object.created_at,
        :updated_at => @object.updated_at,
      }
    end
  end

  class NetworkServiceCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        NetworkService.new(i).generate
      }
    end
  end

  class DhcpRange < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::DhcpRange)
      @object = object
    end

    def generate()
      [@object.range_begin.to_s, @object.range_end.to_s]
    end
  end

  class DhcpRangeCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i| [i.range_begin.to_s, i.range_end.to_s] }
    end
  end

end
