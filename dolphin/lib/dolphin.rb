# -*- coding: utf-8 -*-

require 'parseconfig'
require 'ostruct'
require 'extlib/blank'

Signal.trap(:INT, "EXIT")

$LOAD_PATH.unshift File.expand_path('../', __FILE__)

module Dolphin
  def self.settings(config='')

    if @settings.nil?

      # overwrite
      config = File.join(Dolphin.root_path, '/config/dolphin.conf') if config.blank?
      if !File.exists?(config)
        puts "File not found #{config}"
        exit!
      end

      # TODO:validation
      @config = config
      @settings = ParseConfig.new(config)
    end
    @settings
  end

  def self.config
    @config
  end

  def self.root_path
    File.expand_path('../../', __FILE__)
  end

  def self.templates_path
    File.join(root_path, '/templates')
  end

  def self.config_path
    File.join(root_path, '/config')
  end

  def self.db_path
    File.join(config_path, '/db')
  end

  class EventObject < OpenStruct;end
  class NotificationObject < OpenStruct; end
  class ResponseObject
    attr_accessor :message
    def initialize
      @success = nil
      @message = ''
    end

    def success!
      @success = true
    end

    def success?
      warn 'Does not happened anything.' if @success.nil?
      @success === true
    end

    def fail!
      @success = false
    end

    def fail?
      warn 'Does not happened anything.' if @success.nil?
      @success === false
    end
  end

  class FailureObject < ResponseObject
    def initialize(message = '')
      fail!
      @message = message
      freeze
    end
  end

  class SuccessObject < ResponseObject
    def initialize(message = '')
      success!
      @message = message
      freeze
    end
  end

  autoload :VERSION, 'dolphin/version'

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
    module Message
      autoload :ZabbixHelper, 'dolphin/helpers/message/zabbix_helper'
    end
  end

  # Celluloid supervisor
  autoload :Manager, 'dolphin/manager'

  # Celluloid actors
  autoload :RequestHandler, 'dolphin/request_handler'
  autoload :Worker, 'dolphin/worker'
  autoload :QueryProcessor, 'dolphin/query_processor'
  autoload :Sender, 'dolphin/sender'
end
