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

  class NetworkVif < Dcmgr::Endpoints::ResponseGenerator
    def initialize(network_vif)
      raise ArgumentError if !network_vif.is_a?(Dcmgr::Models::NetworkVif)
      @network_vif = network_vif
    end

    def generate()
      @network_vif.instance_exec {
        api_hash = to_hash.merge(:id=>canonical_uuid)
        api_hash.merge({ :id=>self.canonical_uuid,
                         :network_id => self.network.nil? ? nil : self.network.canonical_uuid,
                       })
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
end
