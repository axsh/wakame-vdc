require 'rubygems'
require 'metric_libs'

module Fluent
  class TextMatcherOutput < Output
    Fluent::Plugin.register_output('text_matcher', self)

    MATCH_PATTERN_MAX_NUM = 100

    config_param :alarm1, :string # string: NAME,REGEXP
    (2..MATCH_PATTERN_MAX_NUM).each do |i|
      config_param ('alarm' + i.to_s).to_sym, :string, :default => nil
    end

    config_param :tag, :string, :default => 'textmatch'

    def initialize
      super
      @cache = {}
      @queue = Queue.new
    end

    def configure(conf)
      super
      @alarms = []
      (1..MATCH_PATTERN_MAX_NUM).each do |i|
        next unless conf["alarm#{i}"]
        match_key, regexp, period = conf["alarm#{i}"].split(',', 3)
        @alarms.push({
          :alarm_id => i,
          :match_key => match_key,
          :match_pattern => Regexp.new(regexp),
          :period => period.to_i
        })
        @cache[match_key] = MetricLibs::TimeSeries.new
      end
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
        user_timer = TimerWatcher.new(alarm[:period], true) {
          if @cache.has_key?(alarm[:match_key]) && @cache[alarm[:match_key]].is_a?(MetricLibs::TimeSeries)

            res = evaluate(@cache[alarm[:match_key]], alarm[:match_pattern])

            message = {
              :alarm_id => alarm[:alarm_id],
              :match_key => alarm[:match_key],
              :match_count => res[:match_count]
            }
            $log.info "evaluate result: #{message}"

            if res[:match_count] > 0
              sample = @cache[alarm[:match_key]].first.value['message']
              message['instance_id'] = sample['x_wakame_instance_id']
              message['account_id'] = sample['x_wakame_account_id']

              Engine.emit(@tag, Engine.now, message)
              $log.info "emit: #{message}"
            end

            # Clear time series data
            @cache[alarm[:match_key]] = MetricLibs::TimeSeries.new

          end
        }
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
        match_key = record['x_wakame_label']
        unless @cache.has_key? match_key
          $log.error "No such matching key in #{record}"
        else
          @cache[match_key].push(record, Time.at(time))
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
          if match_pattern =~ h.value['message']
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
