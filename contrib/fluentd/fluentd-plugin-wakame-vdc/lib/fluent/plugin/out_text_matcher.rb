require 'metric_libs'

module Fluent
  class TextMatcherOutput < Output
    Fluent::Plugin.register_output('text_matcher', self)

    config_param :tag, :string, :default => 'textmatch'
    config_param :alarm1, :string

    # Parserd name key on fluent of Guest VM
    MATCH_KEY = 'message'.freeze

    def initialize
      super
      @monitor = {}
      @cache = {}
      @alarms = []
    end

    def configure(conf)
      alarm_pattern = /^alarm([0-9]+)$/
      Fluent::TextMatcherOutput.module_eval do
        conf.each {|k ,v|
          if m = k.match(alarm_pattern)
            config_param "alarm#{m[1].to_i}".to_sym, :string
          end
        }
      end
      super
      config.each {|k ,v|
        if m = k.match(alarm_pattern)
          resource_id, alarm_id, tag, regexp, evaluation_periods = v.split(',', 5)
          @alarms.push({
            :resource_id => resource_id,
            :alarm_id => alarm_id,
            :tag => tag,
            :match_pattern => Regexp.new(regexp),
            :evaluation_periods => evaluation_periods.to_i
          })

          @cache[resource_id] = {}
          @cache[resource_id][tag] = MetricLibs::TimeSeries.new
        end
      }
    end

    class TimerWatcher < Coolio::TimerWatcher
      def initialize(interval, repeat, &callback)
        @callback = callback
        super(interval, repeat)
      end

      def on_timer
        @callback.call
      rescue
        $log.error $!.to_s
        $log.error_backtrace
      end
    end

    def start
      $log.debug "text_matcher:start:#{Thread.current}"
      @loop = Coolio::Loop.new

      @alarms.each { |alarm|
        $log.info "set alarm #{alarm}"
        user_timer = TimerWatcher.new(alarm[:evaluation_periods], true) {
          resource_id = alarm[:resource_id]
          if @cache[resource_id].has_key?(alarm[:tag])
            now = Time.now
            start_time = now - alarm[:evaluation_periods]
            evaluation_data = @cache[resource_id][alarm[:tag]].find(start_time, now)
            res = evaluate(evaluation_data, alarm[:match_pattern])

            message = {
              :alarm_id => alarm[:alarm_id],
              :tag => alarm[:tag],
              :match_count => res[:match_count]
            }
            $log.info "evaluate result: #{message}"

            if res[:match_count] > 0
              sample = evaluation_data.first.value
              message['resource_id'] = sample['x_wakame_instance_id']
              message['account_id'] = sample['x_wakame_account_id']

              Engine.emit(@tag, Engine.now, message)
              $log.info "emit: #{message}"
            end

            # Clear time series data
            @cache[resource_id][alarm[:tag]] = MetricLibs::TimeSeries.new

          end
        }

        @monitor[alarm[:alarm_id]] = user_timer
        @loop.attach(user_timer)
      }

      if debug_mode?
        @debug_timer = TimerWatcher.new(1, true) {
          $log.debug "tick:#{Thread.current}"
        }
        @loop.attach(@debug_timer)
      end

      @thread = Thread.new(&method(:run))
    end

    def shutdown
      $log.debug "text_matcher:shutdown:#{Thread.current}"
      @loop.stop
      @thread.join
    end

    def emit(tag, es, chain)
      es.each do |time, record|
        resource_id = record['x_wakame_instance_id']
        label = record['x_wakame_label']
        if @cache[resource_id].has_key? label
          @cache[resource_id][label].push(record, Time.at(time))
        else
          $log.error "Does't accepted #{record}"
        end
      end
    end

    def run
      @loop.run
    rescue
      $log.error "unexpected error", :error=>$!.to_s
      $log.error_backtrace
    end

    def evaluate(timeseries, match_pattern)
      match_count = 0
      if timeseries.length > 0
        timeseries.each do |h|
          if match_pattern =~ h.value[MATCH_KEY]
            $log.info "matched: #{h.value}"
            match_count +=1
          else
            $log.debug "unmatched: #{h.value}"
          end
        end
      end

      {
        :match_count => match_count
      }
    end

    private
    def debug_mode?
      $log.level <= Fluent::Log::LEVEL_DEBUG
    end
  end

end
