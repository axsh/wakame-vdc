# -*- coding: utf-8 -*-

require 'parseconfig'
require 'ostruct'
require 'pry'
require 'ltsv'
require 'celluloid'

Signal.trap(:INT, "EXIT")

$LOAD_PATH.unshift File.expand_path('../', __FILE__)

module Dolphin

  def self.settings

    @settings ||= ParseConfig.new(File.join(Dolphin.root_path, '/config/settings'))

    # TODO:validation

    @settings
  end

  def self.root_path
    File.expand_path('../../', __FILE__)
  end

  Celluloid.logger.datetime_format = "%Y-%m-%d %H:%M:%S"
  Celluloid.logger.formatter = proc { |severity, datetime, progname, msg|

    case settings['logger']['format']
      when 'human_readable'
        msg = "[#{msg[:thread_id]}] [#{msg[:classname]}] #{msg[:message]}" if msg.is_a?(Hash)
        Logger::Formatter.new.call(severity, datetime, progname, msg)
      when 'ltsv'
        LTSV.dump({
          :log_level => severity,
          :time => datetime,
          :thread_id => msg[:thread_id],
          :classname => msg[:classname],
          :message => msg[:message],
        }) + "\n"
    end
  }

  class EventObject < OpenStruct;end
  class NotificationObject < OpenStruct; end

  autoload :Util, 'dolphin/util'
  autoload :MessageBuilder, 'dolphin/message_builder'
  autoload :DataBase, 'dolphin/database'

  module Models
    autoload :Base, 'dolphin/models/base'
    autoload :Event, 'dolphin/models/event'
    autoload :Notification, 'dolphin/models/notification'
  end

  module Helpers
    autoload :RequestHelper, 'dolphin/helpers/request_helper'
  end

  # Celluloid supervisor
  autoload :Manager, 'dolphin/manager'

  # Celluloid actors
  autoload :RequestHandler, 'dolphin/request_handler'
  autoload :Worker, 'dolphin/worker'
  autoload :QueryProcessor, 'dolphin/query_processor'
  autoload :Sender, 'dolphin/sender'
end