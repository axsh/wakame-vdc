# -*- coding:utf-8 -*-

module MetricLibs
  class Alarm

    def initialize(alm, manager)
      set_variable(alm)
      @manager = manager
      @resource = MetricLibs::TimeSeries.new
    end

    def update(alm)
      set_variable(alm)
    end

    def feed(data)
      raise ArgumentError unless data.is_a?(Hash)
      metric_name = @metric_name.split('.')
      @resource.push(data[@resource_id][metric_name[0]][metric_name[1]],
        Time.at(data[@resource_id][metric_name[0]]["time"].to_i))
    end

    def evaluate
      time = Time.now
      ev = case @metric_name
           when 'cpu.usage'
             end_time = time.to_i
             start_time = end_time - @evaluation_periods
             values = @resource.find(Time.at(start_time), Time.at(end_time)).map {|v|
          v.value
        }
             usage = values.inject{|sum, n| sum.to_f + n.to_f} / values.size
             usage.method(SUPPORT_COMPARISON_OPERATOR[@params["comparison_operator"]]).call(@params["threshold"])
           when 'memory.usage'
             memory_usage = @resource.last.value.to_f
             memory_usage.method(SUPPORT_COMPARISON_OPERATOR[@params["comparison_operator"]]).call(@params["threshold"])
           else
             raise "Unknown metric name: #{@metric_name}"
           end

      delete_resource(time)
      ev
    end

    private
    def set_variable(alm)
      raise ArgumentError unless alm.is_a?(Hash)
      alm.each {|k, v| instance_variable_set("@#{k}", v) }
    end

    def delete_resource(time)
      raise ArgumentError unless time.is_a?(Time)
      @resource.delete_all_since_at(time)
    end
  end
end

