# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class LoadBalancer < Dcmgr::Endpoints::ResponseGenerator
    def initialize(load_balancer)
      raise ArgumentError if !load_balancer.is_a?(Dcmgr::Models::LoadBalancer)
      @load_balancer = load_balancer
    end

    def generate()
      @load_balancer.instance_exec {
        h = { :id=>canonical_uuid,
              :state=>state,
              :status=>status
        }

        h[:targets] = []
        load_balancer_targets.each { |t|
          h[:targets] << t.to_hash
        }
        h
      }
    end
  end

  class LoadBalancerCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        LoadBalancer.new(i).generate
      }
    end
  end
end
