# -*- coding: utf-8 -*-

require 'metric_libs'
module Dcmgr
  module ResourceMonitor
    class MetricEvaluation
      include Dcmgr::Constants::Alarm

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

      def delete(resource_id, metric, time)
        raise ArgumentError unless resource_id.is_a?(String)
        raise ArgumentError unless metric.is_a?(String)
        raise ArgumentError unless time.is_a?(Time)
        @cache[resource_id][metric].delete_all_since_at(time)
      end

      def evaluate(alarm, time)
        raise ArgumentError unless alarm.is_a?(Hash)
        raise ArgumentError unless time.is_a?(Time)

        case alarm[:metric_name]
        when 'cpu.usage'
          end_time = time.to_i
          start_time = end_time - alarm[:evaluation_periods]
          metric_value = @cache[alarm[:resource_id]][alarm[:metric_name]]

          values = metric_value.find(Time.at(start_time), Time.at(end_time)).map {|v|
            v.value
          }
          cpu_usage = values.inject{|sum, n| sum.to_f + n.to_f} / values.size

          cpu_usage.method(SUPPORT_COMPARISON_OPERATOR[alarm[:params]["comparison_operator"]]).call(alarm[:params]["threshold"])
        when 'memory.usage'
        else
          raise "Unknown metric name: #{alarm[:metric_name]}"
        end
      end

    end
  end
end
