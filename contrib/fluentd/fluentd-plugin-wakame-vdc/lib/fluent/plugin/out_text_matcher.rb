# -*- encoding: utf-8 -*-
require 'metric_libs'
require 'yaml'

MetricLibs::Alarm.class_eval do

  attr_accessor :ipaddr, :notification_timer

  def send_alarm_notification

    if @notification_logs.nil?
      $log.debug("Does now found notification logs")
      return true
    end

    now = Time.now
    start_time = now - @notification_periods
    end_time = now

    # for debug
    @notification_logs.dump

    logs = @notification_logs.find(start_time, end_time)

    if logs.empty?
      $log.debug("Does not found logs")
      return true
    end

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
        :logs => logs.collect {|l| l.value }
      }
    }

    DolphinClient::Event.post(message)
    clear_notification_logs
  end

  def add_notification_timer(timer)
    @notification_timer = timer
  end

  def update_to_repeating_timer(timer)
    if @notification_timer.attached?
      @notification_timer.detach
    end
    @notification_timer = timer
  end

  def clear_histories
    if @timeseries.length > 0
      $log.info("clear histories")
      @timeseries = MetricLibs::TimeSeries.new
    end
  end

  def save_notification_logs

    if @notification_logs.nil?
      @notification_logs = MetricLibs::TimeSeries.new
    end

    @last_evaluated_value.each.collect {|v|
      @notification_logs.push({
        :evaluated_value => v[:match_ranges].reverse.join("\n"),
        :evaluated_at => @last_evaluated_at
      })
    }
    @timeseries = MetricLibs::TimeSeries.new
  end

  def clear_notification_logs
    @notification_logs = nil
  end

end

class LogAlarmManager < MetricLibs::AlarmManager
  include MetricLibs::Constants::Alarm

  attr_reader :alarms_tmp_dir

  ALARM_TMP_FILE = 'tmp.yaml'.freeze

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

  def save_alarms
    @manager.values.each {|v|
      create_alarm_file(v[:alarm].uuid)
      write_alarm_file(v[:alarm].uuid)
    }
  end

  def read_alarms
    alms = []
    Dir.glob(File.join(@alarms_tmp_dir, '*')).each {|path|
      data = File.read(File.join(path, ALARM_TMP_FILE))
      alms << YAML.load(data)
    }
    alms
  end

  def create_alarm_file(uuid)
    path = File.join(alarms_tmp_dir, uuid)
    unless File.exists? path
      FileUtils.mkdir(path)
    end
  end

  def alarms_tmp_dir=(path)
    @alarms_tmp_dir = path
    unless File.exists? path
      FileUtils.mkdir(path)
    end
  end

  def write_alarm_file(uuid)
    path = File.join(alarms_tmp_dir, uuid, ALARM_TMP_FILE)
    alarm = get_alarm(uuid)
    data = {
      'alarm_id'  => alarm.uuid,
    }.to_yaml
    File.write(path, data)
  end

  def delete_alarm_files
    Dir.glob(File.join(@alarms_tmp_dir, '*')).each {|path|
      File.rm(File.join(path, ALARM_TMP_FILE))
    }
  end

  def notify(uuid)
    get_alarm(uuid).send_alarm_notification
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
      @alarm_manager.alarms_tmp_dir = '/var/tmp/fluentd_alarms/'
      set_signal_handlers
    end

    def set_signal_handlers
      Signal.trap(:HUP) {
        $log.info('hup save alarms')
        # @alarm_manager.save_alarms
      }

      Signal.trap(:INT) {
        $log.info('int save alarms')
        exit!
        # @alarm_manager.save_alarms
      }

      Signal.trap(:TERM) {
        $log.info('term save alarms')
        # @alarm_manager.save_alarms
      }
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
          $log.info("set alarm: #{alarm}")
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
        timer = watch_notification_timer({
          :interval => alarm.notification_periods,
          :repeating => true,
          :alarm => alarm
        })
        alarm.add_notification_timer(timer)
      }

      init_timer = TimerWatcher.new(1, false) {
        $log.info('init timer')
      }

      @loop.attach(init_timer)
      @thread = Thread.new(&method(:run))
    end

    def watch_notification_timer(data)
      $log.debug("set notification timer interval(#{data[:interval]}), repeating(#{data[:repeating]}), alarm(#{data[:alarm_id]})")
      timer = TimerWatcher.new(data[:interval], data[:repeating]) {
        $log.debug("call notification timer on #{data[:alarm_id]}")
        data[:alarm].send_alarm_notification
      }
      @loop.attach(timer)
      timer
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

      alarms.each {|alm|
        alm.evaluate
        info_alarm_log("Evaluated alarm", alm)
        alm.save_notification_logs
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
        :match_value => alarm.match_value,
        :last_evaluated_at => alarm.last_evaluated_at
      }
      $log.info("#{message}: #{alarm_values}")
    end

  end
end
