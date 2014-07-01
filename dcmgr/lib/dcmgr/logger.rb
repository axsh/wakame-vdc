# -*- coding: utf-8 -*-

module Dcmgr
  module Logger

    # logger object is set at config/initializers/logger.rb
    def self.logger=(logger)
      @logger = logger
    end

    def self.logger
      @logger || raise("Logger is not initialized yet.")
    end

    def self.log_io
      logger.instance_variable_get(:@logdev).dev
    end

    class CustomLogger
      attr_reader :logger

      def initialize(progname)
        @progname = progname
      end

      ["fatal", "error", "warn", "info", "debug"].each do |level|
        define_method(level){|msg|
          # constant from Isono::NodeModules::JobWorker::JOB_CTX_KEY
          jobctx = Thread.current[:job_worker_ctx]
          if jobctx
            logger.__send__(level, "Session ID: #{jobctx.session_id}: #{msg}")
          else
            logger.__send__(level, "#{msg}")
          end
        }
      end
      alias :warning :warn

      def logger
        require 'logger'
        l = ::Logger.new(Dcmgr::Logger.log_io)
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
