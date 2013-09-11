# -*- encoding: utf-8 -*-
require 'metric_libs'
require 'yaml'
require 'time'
require 'uri'

MetricLibs::Alarm.class_eval do

  ALARM_ERRORS = {
    1 => 'read alarm logs over the limit'
  }.freeze

  attr_accessor :ipaddr, :notification_timer, :next_timer, :match_count

  def send_alarm_notification
    message = {}
    logs = []
    total_match_count = 0
    limit_log = {
      :exceeded => 0,
      :errors_at => []
    }
    state = 'ok'

    if notification_logs.length == 0
      $log.info ("[#{uuid}] does not found notification logs")
    else
      logs = notification_logs.find_all.to_a
      logs = logs.collect {|l|
        total_match_count += 1 unless l.value[:evaluated_value].empty?
        {
          :evaluated_value => encode_str(l.value[:evaluated_value]),
          :evaluated_at => l.value[:evaluated_at].iso8601
        }
      }
    end

    if errors.count > 0 || total_match_count > 0
      message[:notification_id] = @alarm_actions[:notification_id]
      message[:message_type] = @alarm_actions[:message_type]
      state = 'alarm'
    end

    error_no = 1
    if @errors.has_key?(error_no)
      limit_log[:exceeded] = error_no
      limit_log[:errors_at] = @errors[error_no].collect {|e| e[:at].iso8601}
    end

    notified_at = Time.now
    message[:params] = {
      :alert_engine => 'fluentd',
      :state => state,
      :alarm_id => @uuid,
      :metric_name => @metric_name,
      :resource_id => @resource_id,
      :ipaddr => @ipaddr,
      :match_value => encode_str(@match_value),
      :tag => @tag,
      :logs => logs,
      :display_name => encode_str(@display_name),
      :match_count => total_match_count,
      :limit_log => limit_log,
      :notification_periods => @notification_periods,
      :notified_at => notified_at.iso8601
    }

    if errors.count > 0 || total_match_count > 0
      DolphinClient::Event.post(message)
      $log.info("[#{uuid}] send message to dolphin.")
      @last_notified_at = notified_at
    else
      # Doesn't send notification to dolphin.
      $log.debug(message)
    end

    reset_alarm
    clear_notification_logs
  end

  def add_notification_timer(timer)
    @notification_timer = timer
  end

  def get_notification_timer
    @notification_timer
  end

  def save_notification_logs
    if @last_evaluated_value.length > 0
      @last_evaluated_value.each.collect {|v|
        notification_logs.push({
          :evaluated_value => v[:match_ranges].join("\n"),
          :evaluated_at => @last_evaluated_at
        })
      }
    end
  end

  def clear_notification_logs
    @notification_logs.delete_all_since_at(Time.now)
  end

  def clear_alarm_logs
    @timeseries = MetricLibs::TimeSeries.new
  end

  def notification_logs
    @notification_logs ||= MetricLibs::TimeSeries.new
  end

  def add_errors(no)
    errors[no] ||= []
    errors[no] << {
      :message => ALARM_ERRORS[no],
      :at => Time.now
    }
  end

  def errors
    @errors ||= {}
  end

  def reset_alarm
    @errors = {}
  end

  private
  def encode_str(text)
    URI.encode_www_form_component(text)
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
    Dir.glob(File.join(@alarms_tmp_dir, 'alm-*')).each {|path|
      abs_path = File.join(path, ALARM_TMP_FILE)
      if File.exists? abs_path
        alms << YAML.load(File.read(abs_path))
      end
    }
    alms
  end

  def create_alarm_file(uuid)
    path = File.join(@alarms_tmp_dir, uuid)
    unless File.exists? path
      FileUtils.mkdir_p(path)
    end
  end

  def alarms_tmp_dir=(path)
    @alarms_tmp_dir = path
    unless File.exists? path
      FileUtils.mkdir_p(path)
    end
  end

  def write_alarm_file(uuid)
    alarm = get_alarm(uuid)
    unless alarm.nil?
      notification_logs = alarm.notification_logs.find_all.collect{|log| log.value}
      data = {
        'alarm_id'  => alarm.uuid,
        'notification_logs' => notification_logs,
        'elpapsed_time' => alarm.get_notification_timer.elpapsed_time,
        'notification_periods' => alarm.notification_periods,
        'write_time' => Time.now
      }
      $log.info("[#{uuid}] write alarm to temporary file")
      File.write(File.join(alarms_tmp_dir, uuid, ALARM_TMP_FILE), data.to_yaml)
    end
  end

  def delete_alarm_files
    Dir.glob(File.join(@alarms_tmp_dir, 'alm-*')).each {|path|
      FileUtils.rm_rf(path)
    }
  end

end

module Fluent
  class TextMatcherOutput < Output
    Fluent::Plugin.register_output('text_matcher', self)

    config_param :dolphin_server_uri
    config_param :tag, :string, :default => 'textmatch'
    config_param :max_read_message_bytes, :integer, :default => -1
    config_param :max_match_count, :integer, :default => -1

    # Parserd name key on fluent of Guest VM
    MATCH_KEY = 'message'.freeze

    def initialize
      super
      require 'dolphin_client'
      require 'csv'

      @alarm_manager = LogAlarmManager.new
      @alarm_manager.alarms_tmp_dir = '/var/tmp/fluentd_alarms/'
    end

    def configure(conf)
      $log.info("Load config: #{conf}")
      $log.info("max_read_message_bytes=\"#{@max_read_message_bytes}\"")
      $log.info("max_match_count=\"#{@max_match_count}\"")

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
        if k.match(alarm_pattern)

          values = CSV.parse_line(decode_str(v))
          alarm_actions = {}
          resource_id = values[0]
          alarm_id = values[1]
          tag = values[2]
          match_pattern = values[3]
          notification_periods = values[4].to_i
          enabled = values[5] == 'true' ? true : false
          alarm_actions[:notification_id], alarm_actions[:message_type] = values[6].split(':')
          display_name = values[7]

          if enabled
            alarm = {
              :uuid => alarm_id,
              :resource_id => resource_id,
              :tag => tag,
              :match_pattern => match_pattern,
              :match_value => match_pattern,
              :notification_periods => notification_periods,
              :enabled => enabled,
              :alarm_actions => alarm_actions,
              :metric_name => 'log',
              :display_name => display_name,
              :max_match_count => @max_match_count
            }
            @alarm_manager.update(alarm)
            $log.info("set alarm: #{alarm}")
          end
        end
      }

      @loop = Coolio::Loop.new

      DolphinClient.domain = @dolphin_server_uri
    end

    class TimerWatcher < Coolio::TimerWatcher
      def initialize(interval, repeat, &callback)
        @callback = callback
        reset_elpapsed_time
        super(interval, repeat)
      end

      def on_timer
        @callback.call
        reset_elpapsed_time
      rescue
        $log.error $!.to_s
        $log.error_backtrace
      end

      def elpapsed_time
        Time.now - @elpapsed_time
      end

      def reset_elpapsed_time
        @elpapsed_time = Time.now
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
      # Load temporary alarms if fluentd has been terminated.
      tmp_alarms = @alarm_manager.read_alarms
      if tmp_alarms.length > 0
        tmp_alarms.each {|alm|
          alarm = @alarm_manager.get_alarm(alm['alarm_id'])
          next if alarm.nil?
          alm['notification_logs'].each {|log|
            alarm.notification_logs.push(log)
          }

          stop_time = Time.now - alm['write_time']

          $log.info "[#{alm['alarm_id']}] write time #{alm['write_time']} on temporary file"
          $log.info "[#{alm['alarm_id']}] system stop time #{stop_time}"
          $log.info "[#{alm['alarm_id']}] elpapsed time #{alm['elpapsed_time']}"

          if alm['notification_periods'] < stop_time
            $log.info("[#{alm['alarm_id']}] directry send alarm notification")
            alarm.send_alarm_notification
          else
            next_notification_time = alarm.notification_periods - alm['elpapsed_time']

            $log.info "[#{alm['alarm_id']}] wait notifcation. next time #{next_notification_time}"

            alarm.next_timer = Proc.new {
              timer = watch_notification_timer({
                :interval => alarm.notification_periods,
                :repeating => true,
                :alarm => alarm
              })
              alarm.add_notification_timer(timer)
            }

            timer = watch_notification_timer({
              :interval => next_notification_time,
              :repeating => false,
              :alarm => alarm
            })
            alarm.add_notification_timer(timer)
          end
        }
        @alarm_manager.delete_alarm_files
      end

      @alarm_manager.find_log_alarm.each {|alarm|
        unless alarm.next_timer
          timer = watch_notification_timer({
            :interval => alarm.notification_periods,
            :repeating => true,
            :alarm => alarm
          })
          alarm.add_notification_timer(timer)
        else
          $log.info("[#{alarm.uuid}] skip notification timer ")
        end
      }

      if debug_mode?
        init_timer = TimerWatcher.new(1, true) {
          @alarm_manager.find_log_alarm.each{|alarm|
            $log.debug("[#{alarm.uuid}] #{alarm.get_notification_timer.elpapsed_time}")
          }
        }
      else
        init_timer = TimerWatcher.new(1, false) {
        }
      end

      @loop.attach(init_timer)
      @thread = Thread.new(&method(:run))
    end

    def watch_notification_timer(data)
      $log.debug("set notification timer interval(#{data[:interval]}), repeating(#{data[:repeating]}), alarm(#{data[:alarm].uuid})")
      timer = TimerWatcher.new(data[:interval], data[:repeating]) {
        $log.debug("call notification timer on #{data[:alarm_id]}")
        data[:alarm].send_alarm_notification

        if data[:alarm].next_timer.is_a? Proc
          $log.info("[#{data[:alarm].uuid}] call next timer")
          data[:alarm].next_timer.call

          $log.info("[#{data[:alarm].uuid}] remove next timer")
          data[:alarm].next_timer = nil
        end
      }
      @loop.attach(timer)
      timer
    end

    def shutdown
      $log.info('starting shutdown')
      @loop.stop if @loop
      @thread.join
      @alarm_manager.save_alarms
      $log.info('end shutdown')
    end

    def emit(tag, es, chain)
      sample = es.first[1]
      instance_tag = sample['x_wakame_label']
      resource_id = sample['x_wakame_instance_id']
      ipaddr = sample['x_wakame_ipaddr']
      alarms = @alarm_manager.find_log_alarm(resource_id, instance_tag)
      messages = es.reverse_each.collect{|time, record| [time , record['message']]}

      $log.info("[#{resource_id}] [#{instance_tag}] starting emit process")
      alarms.each{|alm|
        alm.ipaddr ||= ipaddr
        read_message_bytes = 0
        messages.each {|time, message|

          read_message_bytes += message.bytesize
          if (@max_read_message_bytes > read_message_bytes) || @max_read_message_bytes == -1
            alm.feed({
              'log' => message,
              'time' => Time.at(time)
            })
          else
            alm.add_errors(1)
            $log.warn "can't read message bytes over #{@max_read_message_bytes} bytes for #{alm.uuid}"
            break
          end
        }
        $log.debug("read message #{read_message_bytes} bytes for #{alm.uuid}")
      }

      alarms.each {|alm|
        alm.evaluate
        if @max_match_count != -1 && alm.max_match_count < alm.match_count
          $log.warn "[#{alm.uuid}] max_match_count over #{@max_match_count}."
        end
        $log.info("[#{resource_id}] [#{instance_tag}] [#{alm.uuid}] evaluated")
        alm.save_notification_logs
        alm.clear_alarm_logs
      }
      $log.info("[#{resource_id}] [#{instance_tag}] end emit process")
    end

    private

      def decode_str(text)
        URI.decode_www_form_component(text)
      end

    def debug_mode?
      $log.level <= Fluent::Log::LEVEL_DEBUG
    end
  end
end
