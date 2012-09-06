# -*- coding: utf-8 -*-
require 'logger'

module Dcmgr
  module Logger

    # for passenger, messages in STDOUT are not appeared in
    # error.log. $> is changed in initializers/logger.rb as per the
    # server environment. so that here also refers $> instead of STDOUT or
    # STDERR constant.
    @logdev = ::Logger::LogDevice.new($>)

    def self.default_logdev
      @logdev
    end

    def self.logger
      @logger ||= Logger.create
    end

    # Factory method for ::Logger
    def self.create(name=nil)
      l = ::Logger.new(default_logdev)
      l.progname = name
      l
    end
    
    def self.included(klass)
      klass.class_eval {

        @class_logger = Logger.create(self.to_s.split('::').last)

        def self.logger
          @class_logger
        end

        def logger
          self.class.logger
        end

        def self.logger_name
          @class_logger.progname
        end

        def self.logger_name=(name)
          @class_logger.progname = name
        end
      }
    end
    
  end
end
