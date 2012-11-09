# -*- coding: utf-8 -*-
require 'logger'
require 'isono'

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

    class CustomLogger < Isono::Runner::RpcServer::EndpointBuilder
      def initialize(progname)
        @progname = progname
      end
      
      ["fatal", "error", "warn", "info", "debug"].each do |level|
        define_method(level){|msg|
          if job_context
            logger.__send__(level, "Session ID: #{session_id}: #{msg}")
          else
            logger.__send__(level, "#{msg}")
          end
        }
      end

      # Factory method for ::Logger
      def logger
        l = ::Logger.new(Dcmgr::Logger.default_logdev)
        l.progname = @progname
        l
      end
    end

    def self.included(klass)
      klass.class_eval {

        @class_logger = CustomLogger.new(self.to_s.split('::').last)

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
