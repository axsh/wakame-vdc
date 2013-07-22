# -*- coding: utf-8 -*-
require 'pry'

module Dcmgr
  module ResourceMonitor
    class MetricCapture
      include Dcmgr::Logger
      
      def initialize
        @cache = {}
      end

      def push(hash)
        raise ArgumentError unless hash.is_a?(Hash)
        hash.each { |k,v|
          @cache[k] ||= {}
          v.each { |k2,v2|
            @cache[k][k2] ||= {}
            @cache[k][k2][v2["time"]] = v2
          }
        }
      end

      def get(resource_id, metric)
        return if @cache.empty?
        raise ArgumentError unless resource_id.is_a?(String)
        raise ArgumentError unless metric.is_a?(String)
        @cache[resource_id][metric]
      end

      def delete(resource_id, metric, data)
        return if data.nil?
        raise ArgumentError unless resource_id.is_a?(String)
        raise ArgumentError unless metric.is_a?(String)
        raise ArgumentError unless data.is_a?(Hash)
        p @cache[resource_id][metric]
        data.values.each { |h|
          @cache[resource_id][metric].delete(h["time"])
        }
        p @cache[resource_id][metric]
      end
    end
  end
end
