# -*- coding: utf-8 -*-

require 'metric_libs'
module Dcmgr
  module ResourceMonitor
    class MetricEvaluation
      COMPARISON_OPERATOR = {
        :gt => :>,
        :ge => :>=,
        :lt => :<,
        :le => :<=,
        }

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
            @cache[resource_id]["#{metric}.#{k}"] ||= MetricLibs::TimeSeries.new
            @cache[resource_id]["#{metric}.#{k}"].push(v, Time.at(h["time"].to_i))
          }
        }
      end

      def delete
      end

      def evaluate(alarm)
        raise ArgumentError unless alarm.is_a?(Hash)
        
        case alarm[:metric_name]
        when 'cpu.usage'
          end_time = Time.now.to_i
          start_time = end_time - alarm[:params]["period"]
          metric_value = @cache[alarm[:resource_id]]["cpu.total_usage"]

          values = metric_value.find(Time.at(start_time), Time.at(end_time)).map {|v|
            v.value
          }
          cpu_usage = values.inject{|sum, n| sum.to_f + n.to_f} / values.size

          cpu_usage.method(COMPARISON_OPERATOR[alarm[:params]["comparison_operator"].to_sym]).call(alarm[:params]["threshold"])
        when 'memory.usage'
        else
          raise "Unknown metric name: #{alarm[:metric_name]}"
        end
      end

    end
  end
end
