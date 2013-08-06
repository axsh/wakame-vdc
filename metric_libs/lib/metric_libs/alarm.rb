# -*- coding:utf-8 -*-

module MetricLibs
  class Alarm
    include MetricLibs::Constants::Alarm

    attr_reader :uuid, :resource_id, :metric_name

    def initialize(alm, manager)
      set_variable(alm)
      @manager = manager
      @resource = MetricLibs::TimeSeries.new
      @error_count = 0
    end

    def update(alm)
      set_variable(alm)
    end

    def feed(data)
      raise ArgumentError unless data.is_a?(Hash)
      if data["timeout"]
        @resource.push(nil, Time.at(data["time"].to_i))
      else
        @resource.push(data[@metric_name], Time.at(data["time"].to_i))
      end
    end

    def evaluate
      case @metric_name
      when 'cpu.usage'
        end_time = Time.now.to_i
        start_time = end_time - @evaluation_periods

        values = @resource.find(Time.at(start_time), Time.at(end_time)).map {|v|
          v.value
        }

        if values.empty? || values.size <= 1
          @error_count += 1
          @resource.delete_first
          return false
        end

        usage = values.inject{|sum, n| sum.to_f + n.to_f} / values.size
        ev = usage.method(SUPPORT_COMPARISON_OPERATOR[@params["comparison_operator"]]).call(@params["threshold"])
        @resource.delete_first
        ev
      when 'memory.usage'
        memory_usage = @resource.last.value
        if values.empty?
          @error_count += 1
          @resource.delete_first
          return false
        end

        ev = memory_usage.to_f.method(SUPPORT_COMPARISON_OPERATOR[@params["comparison_operator"]]).call(@params["threshold"])
        @resource.delete_first
        ev
      else
        raise "Unknown metric name: #{@metric_name}"
      end
    end

    def evaluate?
      case @metric_name
      when "cpu.usage"
        return false if @resource.length <= 1
      when "memory.usage"
      end
      @resource.length >= @evaluation_count ? true : false
    end

    private
    def set_variable(alm)
      raise ArgumentError unless alm.is_a?(Hash)
      alm.each {|k, v| instance_variable_set("@#{k}", v) }
      @evaluation_count = @evaluation_periods.to_i / @capture_periods.to_i unless @capture_periods.nil?
    end

    def delete_resource(time)
      raise ArgumentError unless time.is_a?(Time)
      @resource.delete_all_since_at(time)
    end
  end
end

