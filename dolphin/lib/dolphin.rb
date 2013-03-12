# -*- coding: utf-8 -*-

require 'parseconfig'
require 'ostruct'
require 'pry'

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

  def self.templates_path
    File.join(root_path, '/templates')
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