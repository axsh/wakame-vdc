module Wakame
  module AgentManagers
    class MonitorManager
      include AgentManager

      def init
        agent_mon = register(Monitor::Agent.new, '/agent')
        register(Monitor::Service.new, '/service')
        
        agent_mon.reload({:interval=>10})
      end

      def terminate
      end
      
      attr_reader :monitors
      
      def initialize()
        @monitors = {}
      end
      
      def register(monitor, path=nil)
        raise '' unless monitor.kind_of?(Wakame::Monitor)
        
        if path.nil?
          path = '/' + Util.to_const_path(monitor.class.to_s)
        end
        
        if @monitors.has_key?(path)
          Wakame.log.error("#{self.class}: Duplicate registration: #{path}")
          raise "Duplicate registration: #{path}"
        end
        
        monitor.agent = self.agent
        @monitors[path] = monitor
      end
      
      def unregister(path)
        @monitors.delete(path)
      end
      
      def find_monitor(path)
        @monitors[path]
      end
      
    end
  end
end
