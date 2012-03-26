# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Network < Dcmgr::Endpoints::ResponseGenerator
    def initialize(network)
      raise ArgumentError if !network.is_a?(Dcmgr::Models::Network)
      @network = network
    end

    def generate()
      @network.instance_exec {
        to_hash.merge(:id=>canonical_uuid)
      }
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

  class NetworkPort < Dcmgr::Endpoints::ResponseGenerator
    def initialize(network_port)
      raise ArgumentError if !network_port.is_a?(Dcmgr::Models::NetworkPort)
      @network_port = network_port
    end

    def generate()
      @network_port.instance_exec {
        api_hash = to_hash.merge(:id=>canonical_uuid)
        api_hash.delete(:instance_nic_id)
        api_hash.merge({:id=>self.canonical_uuid,
                         :attachment => self.instance_nic.nil? ? {} : {"id" => self.instance_nic.canonical_uuid},
                         :network_id => self.network.nil? ? nil : self.network.canonical_uuid,
                       })
      }
    end
  end

  class NetworkPortCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        NetworkPort.new(i).generate
      }
    end
  end
end
