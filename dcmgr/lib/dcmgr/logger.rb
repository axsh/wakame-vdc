# -*- coding: utf-8 -*-
require 'logger'

module Dcmgr
  module Logger

    @logdev = ::Logger::LogDevice.new(STDOUT)

    def self.default_logdev
      @logdev
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
