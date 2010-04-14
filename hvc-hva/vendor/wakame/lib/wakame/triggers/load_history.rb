
module Wakame
  module Triggers
    class LoadHistoryMonitor < Trigger
      class AgentLoadHighEvent < Wakame::Event::Base
        attr_reader :agent, :load_avg
        def initialize(agent, load_avg)
          super()
          @agent = agent
          @load_avg = load_avg
        end
      end
      class AgentLoadNormalEvent < Wakame::Event::Base
        attr_reader :agent, :load_avg
        def initialize(agent, load_avg)
          super()
          @agent = agent
          @load_avg = load_avg
        end
      end
      class ServiceLoadHighEvent < Wakame::Event::Base
        attr_reader :service_property, :load_avg
        def initialize(svc_prop, load_avg)
          super()
          @service_property = svc_prop
          @load_avg = load_avg
        end
      end
      class ServiceLoadNormalEvent < Wakame::Event::Base
        attr_reader :service_property, :load_avg
        def initialize(svc_prop, load_avg)
          super()
          @service_property = svc_prop
          @load_avg = load_avg
        end
      end

      def initialize
        @agent_data = {}
        @service_data = {}
        @high_threashold = 1.2
        @history_period = 3
      end
      
      def register_hooks(cluster_id)
        event_subscribe(Event::AgentMonitored) { |event|
          @agent_data[event.agent.agent_id]={:load_history=>[], :last_event=>:normal}
          service_cluster.properties.each { |klass, prop|
            @service_data[klass] ||= {:load_history=>[], :last_event=>:normal}
          }
        }
        event_subscribe(Event::AgentUnMonitored) { |event|
          @agent_data.delete(event.agent.agent_id)
        }

        event_subscribe(Event::AgentPong) { |event|
          calc_load(event.agent)
        }
      end

      private
      def calc_load(agent)
        data = @agent_data[agent.agent_id] || next
        data[:load_history] << agent.attr[:uptime]
        Wakame.log.debug("Load History for agent \"#{agent.agent_id}\": " + data[:load_history].inspect )
        detect_threadshold(data, proc{
                             ED.fire_event(AgentLoadHighEvent.new(agent, data[:load_history][-1]))
                           }, proc{
                             ED.fire_event(AgentLoadNormalEvent.new(agent, data[:load_history][-1]))
                           })
        
#         service_cluster.services.each { |id, svc|
#           next unless agent.services.keys.include? id
#           data = @service_data[svc.property.class.to_s] || next

#           data[:load_history] << agent.attr[:uptime]
#           Wakame.log.debug("Load History for service \"#{svc.property.class}\": " + data[:load_history].inspect )
#           detect_threadshold(data, proc{
#                                ED.fire_event(ServiceLoadHighEvent.new(svc.property, data[:load_history][-1]))
#                              }, proc{
#                                ED.fire_event(ServiceLoadNormalEvent.new(svc.property, data[:load_history][-1]))
#                              })
#         }

      end

      def detect_threadshold(data, when_high, when_low)
        hist = data[:load_history]
        if hist.size >= @history_period

          all_higher = hist.all? { |h| h > @high_threashold }

          if data[:last_event] == :normal && all_higher
            when_high.call
            data[:last_event] = :high
          end
          if data[:last_event] == :high && !all_higher
            when_low.call
            data[:last_event] = :normal
          end
        end
        hist.shift while hist.size > @history_period
      end

    end
  end
end
