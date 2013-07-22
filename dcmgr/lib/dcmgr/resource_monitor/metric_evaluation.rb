# -*- coding: utf-8 -*-

require 'metric_libs'
module Dcmgr
  module ResourceMonitor
    class MetricEvaluation
      def initialize
        @cache = {}
      end

      def push(resource_id, metric, hash)
        return if hash.nil?
        raise ArgumentError unless resource_id.is_a?(String)
        raise ArgumentError unless metric.is_a?(String)
        raise ArgumentError unless hash.is_a?(Hash)
        @cache[resource_id] ||= {}
        hash.values.each{ |h|
          h.each{ |k,v|
            ts = MetricLibs::TimeSeries.new
            @cache[resource_id]["#{metric}.#{k}"] ||= {}
            @cache[resource_id]["#{metric}.#{k}"] = ts.push(v, Time.at(h["time"].to_i))
          }
        }
      end

      def delete
      end

      def evaluate
      end
    end
  end
end
