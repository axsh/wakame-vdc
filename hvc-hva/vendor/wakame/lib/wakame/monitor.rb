


module Wakame
  module Monitor
    STATUS_OFFLINE=0
    STATUS_ONLINE=1
    STATUS_FAIL=2

    def self.included(klass)
      klass.class_eval {
        attr_accessor :status, :agent

      }
    end

    def enable
    end

    def disable
    end

    def reload(config)
    end

    def publish_to(exchange, data)
      agent.publish_to(exchange, data)
    end

  end
end


module Wakame
  module Monitor
    class CheckerTimer < EventMachine::PeriodicTimer
      def initialize(time, &blk)
        @interval = time
        @code = proc {
          begin
            blk.call
          rescue => e
            Wakame.log.error(e)
          end
        }
        stop
      end

      def start
        if !running?
          @cancelled = false
          schedule
        end
      end

      def stop
        @cancelled = true
      end

      def running?
        !@cancelled 
      end

    end
  end
end
