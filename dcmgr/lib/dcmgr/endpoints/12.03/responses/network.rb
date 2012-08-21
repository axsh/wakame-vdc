# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Network < Dcmgr::Endpoints::ResponseGenerator
    def initialize(network)
      raise ArgumentError if !network.is_a?(Dcmgr::Models::Network)
      @network = network
    end

    def generate()
      @network.to_api_document
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

  class NetworkService < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::NetworkService)
      @object = object
    end

    def generate()
      @object.to_api_document
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
