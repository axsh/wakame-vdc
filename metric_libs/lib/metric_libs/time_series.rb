# -*- coding: utf-8 -*-

require 'set'
require 'forwardable'

module MetricLibs
  class TimeSeries
    extend Forwardable

    def_delegators :@timeseries, :each, :to_a, :length, :first

    def initialize
      @timeseries = SortedSet.new
    end

    def push(value, time=Time.new)
      @timeseries << MetricValue.new(value, time)
    end

    def find(start_time, end_time)
      unless [start_time, end_time].all? {|t| t.is_a? Time }
        raise ArgumentError, "Not Time class"
      end

      ts = @timeseries.select {|mv|
        if end_time.tv_nsec == 0
          end_time = Time.at(end_time, 999999)
        end

        if start_time <= mv.timestamp && end_time >= mv.timestamp
          mv.value
        end
      }
      ts
    end

    def delete_all_since_at(time)
      unless time.is_a? Time
        raise ArgumentError, "Not Time class"
      end
      @timeseries.delete_if {|mv| time > mv.timestamp}
    end

    def dump
      @timeseries.each{|k, v|
        puts "#{k.timestamp}.#{k.timestamp.nsec} #{k.value}"
      }
      nil
    end
  end
end
