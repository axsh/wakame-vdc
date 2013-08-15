# -*- coding:utf-8 -*-

module MetricLibs
  module AlarmError
    class EvaluationError < Exception; end
  end
  
  class Alarm
    include MetricLibs::Constants::Alarm
    include AlarmError

    attr_reader :uuid, :resource_id, :metric_name, :last_evaluated_value, :last_evaluated_at

    def initialize(alm, manager)
      alm.keys.each{|key|
        self.class.__send__(:attr_accessor, key)
      }
      set_variable(alm)
      @manager = manager
      @timeseries = MetricLibs::TimeSeries.new
      @error_count = 0
    end

    def update(alm)
      set_variable(alm)
    end

    def feed(data)
      raise ArgumentError unless data.is_a?(Hash)
      @timeseries.push(data[@metric_name], data["time"])
    end

    def evaluate
      @before_state = @state
      begin
        case @metric_name
        when 'cpu.usage'
          end_time = Time.now.to_i
          start_time = end_time - @evaluation_periods

          values = @timeseries.find(Time.at(start_time), Time.at(end_time)).map {|v|
            v.value
          }

          raise EvaluationError if values.empty? || values.size <= 1

          evaluated_value = update_last_evaluated_value(values.inject{|sum, n| sum.to_f + n.to_f} / values.size)
          update_state(evaluated_value.method(SUPPORT_COMPARISON_OPERATOR[@params["comparison_operator"]]).call(@params["threshold"]) ? ALARM_STATE : OK_STATE)
        when 'memory.usage'
          evaluated_value = update_last_evaluated_value(@timeseries.last.value)
          raise EvaluationError if evaluated_value.empty?

          update_state(evaluated_value.to_f.method(SUPPORT_COMPARISON_OPERATOR[@params["comparison_operator"]]).call(@params["threshold"]) ? ALARM_STATE : OK_STATE)
        when 'log'
          tmp = []
          match_count = 0
          match_indexes = []
          line_no = 0

          @timeseries.find_all.reverse_each {|t|
            tmp << t.value
            if match_pattern =~ t.value
              match_indexes << line_no
              match_count += 1
            end
            line_no += 1
          }

          pre_read_size = 3
          post_read_size = 3
          evaluated_value = []
          match_indexes.each {|matched_line|
            m = {
              :match_line => tmp[matched_line]
            }

            if 0 > (matched_line - pre_read_size)
              m[:match_ranges] = tmp[0..(matched_line+post_read_size)]
            else
              m[:match_ranges] = tmp[(matched_line-pre_read_size)..(matched_line+post_read_size)]
            end
            evaluated_value << m
          }
          update_last_evaluated_value(evaluated_value)
        else
          raise "Unknown metric name: #{@metric_name}"
        end
        reset_error_count
      rescue =>e
        add_error_count
        update_state(INSUFFICIENT_DATA_STATE) if evaluation_error?
      ensure
        update_last_evaluated_at
        delete_resource
      end
      self.to_hash
    end

    def evaluate?
      case @metric_name
      when "cpu.usage"
        return false if @timeseries.length <= 1
      when "memory.usage"
      end
      @timeseries.length >= @evaluation_count ? true : false
    end

    def changed_state?
      return false if @before_state.empty?
      @state != @before_state
    end

    def enabled?
      @enabled
    end

    def to_hash
      h = {}
      self.instance_variables.map {|v|
       h[v.to_s.delete('@')] = instance_variable_get(v) 
      }
      h.delete("manager") if h.has_key?("manager")
      h.delete("timeseries") if h.has_key?("timeseries")
      h
    end

    private
    def set_variable(alm)
      raise ArgumentError unless alm.is_a?(Hash)
      alm.each {|k, v| instance_variable_set("@#{k}", v) }
      @evaluation_count = @evaluation_periods.to_i / @capture_periods.to_i unless @capture_periods.nil?
    end

    def delete_resource
      @timeseries.delete_first
    end

    def delete_resources(time)
      raise ArgumentError unless time.is_a?(Time)
      @timeseries.delete_all_since_at(time)
    end

    def add_error_count
      @error_count += 1
    end

    def reset_error_count
      @error_count = 0
    end

    def evaluation_error?
      @error_count >= METRICS_ERROR_COUNT[@metric_name]
    end

    def update_state(state)
      raise ArgumentError unless state.is_a?(String)
      @state = state
      @state_timestamp = Time.now
    end

    def update_last_evaluated_value(value)
      @last_evaluated_value = value
    end

    def update_last_evaluated_at
      @last_evaluated_at = Time.now
    end
      
  end
end

