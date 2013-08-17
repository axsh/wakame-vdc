# -*- encoding: utf-8 -*-
require 'metric_libs'

MetricLibs::Alarm.class_eval do

  attr_accessor :ipaddr

  def send_alarm_notification
    logs = @last_evaluated_value.collect {|v|
      {
        :evaluated_value => v[:match_ranges].reverse.join("\n"),
        :evaluated_at => @last_evaluated_at
      }
    }

    message = {
      :notification_id => @alarm_actions[:notification_id],
      :message_type => @alarm_actions[:message_type],
      :params => {
        :alert_engine => 'fluentd',
        :state => 'alarm',
        :alarm_id => @uuid,
        :metric_name => @metric_name,
        :resource_id => @resource_id,
        :ipaddr => @ipaddr,
        :match_value => @match_value,
        :tag => @tag,
        :logs => logs
      }
    }
    DolphinClient::Event.post(message)
  end
end

class LogAlarmManager < MetricLibs::AlarmManager
  include MetricLibs::Constants::Alarm
  def find_log_alarm(resource_id=nil, tag=nil)
    if resource_id.nil?
      alarms = @manager.values
    else
      if tag.nil?
        alarms = @manager.values.select {|alm|
          (alm[:alarm].resource_id == resource_id)
        }
      else
        alarms = @manager.values.select {|alm|
          (alm[:alarm].resource_id == resource_id) && (alm[:alarm].tag == tag)
        }
      end
    end

    return [] if alarms.empty?
    alarms.collect {|a| a[:alarm]}
  end

  def clear_histories(uuid)
    get_alarm(uuid).instance_variable_set(:@timeseries, MetricLibs::TimeSeries.new)
  end

  def get_alarm_hitories(uuid)
    get_alarm(uuid).instance_variable_get(:@timeseries)
  end

end

module Fluent
  class TextMatcherOutput < Output
    Fluent::Plugin.register_output('text_matcher', self)

    config_param :dolphin_server_uri
    config_param :tag, :string, :default => 'textmatch'
    config_param :max_read_message_bytes, :integer, :default => -1
    # config_param :alarm1, :string

    # Parserd name key on fluent of Guest VM
    MATCH_KEY = 'message'.freeze

    class ReadMessageBytesError < Exception; end

    include MetricLibs::Constants::Alarm

    def initialize
      super
      require 'dolphin_client'
      require 'csv'
      @alarm_manager = LogAlarmManager.new
    end

    def configure(conf)
      $log.info("Load config: #{conf}")
      $log.info("max_read_message_bytes=\"#{@max_read_message_bytes}\"")

      alarm_pattern = /^alarm([0-9]+)$/
      Fluent::TextMatcherOutput.module_eval do
        conf.each {|k ,v|
          if m = k.match(alarm_pattern)
            config_param "alarm#{m[1].to_i}".to_sym, :string
          end
        }
      end

      super

      # TODO: Flush messages when fluentd reloaded

      config.each {|k ,v|
        if k.match(alarm_pattern)

          values = CSV.parse_line(v)
          alarm_actions = {}

          resource_id = values[0]
          alarm_id = values[1]
          tag = values[2]
          match_pattern = values[3]
          notification_periods = values[4].to_i
          enabled = values[5] == 'true' ? true : false
          alarm_actions[:notification_id], alarm_actions[:message_type] = values[6].split(':')

          alarm = {
            :uuid => alarm_id,
            :resource_id => resource_id,
            :tag => tag,
            :match_pattern => Regexp.new(match_pattern),
            :match_value => match_pattern,
            :notification_periods => notification_periods,
            :enabled => enabled,
            :alarm_actions => alarm_actions,
            :metric_name => 'log'
          }

          @alarm_manager.update(alarm)
          $log.info("Set alarm: #{alarm}")
        end
      }

      @loop = Coolio::Loop.new

      DolphinClient.domain = @dolphin_server_uri
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

    def run
      if @loop.watchers.size > 0
        @loop.run
      end
    rescue
      $log.error "unexpected error", :error=>$!.to_s
      $log.error_backtrace
    end

    def start
      $log.debug"text_matcher:start:#{Thread.current} :start"

      @alarm_manager.find_log_alarm.each {|alarm|
        if alarm.enabled?
          user_notification_timer = TimerWatcher.new(alarm.to_hash["notification_periods"], true) {
          }
          @loop.attach(user_notification_timer)
        end
      }

      @thread = Thread.new(&method(:run))
    end

    def shutdown
      if @loop.has_active_watchers?
        @loop.stop
      end
      @thread.join
    end

    def emit(tag, es, chain)
      sample = es.first[1]
      instance_tag = sample['x_wakame_label']
      resource_id = sample['x_wakame_instance_id']
      ipaddr = sample['x_wakame_ipaddr']
      alarms = @alarm_manager.find_log_alarm(resource_id, instance_tag)
      messages = es.reverse_each.collect{|time, record| [time , record['message']]}
      read_message_bytes = 0

      begin
        alarms.each{|alm|
          messages.each {|time, message|
            read_message_bytes += message.bytesize

            if @max_read_message_bytes > read_message_bytes
              raise ReadMessageBytesError
            end

            alm.ipaddr = ipaddr
            alm.feed({
              'log' => message,
              'time' => Time.at(time)
            })
          }
        }
      rescue ReadMessageBytesError => e
        # TODO: error message send to dolphin.
        $log.warn "Can't read message bytes over #{@max_read_message_bytes}."
      end

      # evaluate
      alarms.each {|alm|
        alm.evaluate
        info_alarm_log("Evaluated alarm", alm)
      }

      # notification
      alarms.each {|alm|
        alm.send_alarm_notification
        info_alarm_log("Notify alarm", alm)
      }

      # clear alarm histories
      alarms.each {|alm|
        @alarm_manager.clear_histories(alm.uuid)
        $log.info("Clear alarm", alm.uuid)
      }
    end

    private
    def debug_mode?
      $log.level <= Fluent::Log::LEVEL_DEBUG
    end

    def info_alarm_log(message, alarm)
      alarm_values = {
        :uuid => alarm.uuid,
        :resource_id => alarm.resource_id,
        :tag => alarm.tag,
        :alarm_actions => alarm.alarm_actions,
        :ipaddr => alarm.ipaddr,
        :match_value => alarm.match_value
      }
      $log.info("#{message}: #{alarm_values}")
    end

  end
end
