# -*- coding: utf-8 -*-

module MetricLibs
  class MetricValue

    include Comparable

    attr_reader :timestamp, :value

    def initialize(value, time=Time.new)
      unless time.is_a? Time
        raise ArgumentError, "Not Time class"
      end

      @timestamp = time
      @value = value
    end

    def <=>(other)
      @timestamp <=> other.timestamp
    end

  end
end
