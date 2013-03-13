# -*- coding: utf-8 -*-

# require 'dcmgr/endpoints/12.03/responses/dc_network'

module Dcmgr::Endpoints::V1203::Responses
  class IpPool < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::IpPool)
      @object = object
    end

    def generate()
      @object.instance_exec {
        { :id => self.canonical_uuid,
          :display_name => self.display_name,
          :dc_networks => DcNetworkCollection.new(self.dc_networks_dataset).generate,
        }
      }
    end
  end

  class IpPoolCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        IpPool.new(i).generate
      }
    end
  end

  class IpHandle < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::IpHandle)
      @object = object
    end

    def generate()
      @object.instance_exec {
        { :id => self.canonical_uuid,
          :network => self.ip_lease.network ? self.ip_lease.network.canonical_uuid : nil,
          :network_vif => self.ip_lease.network_vif ? self.ip_lease.network_vif.canonical_uuid : nil,
          :ipv4 => self.ip_lease.ipv4_s,
          :display_name => self.display_name,
        }
      }
    end
  end

  class IpHandleCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        IpHandle.new(i).generate
      }
    end
  end

end
