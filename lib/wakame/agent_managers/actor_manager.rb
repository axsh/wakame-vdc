
module Wakame
  module AgentManagers
    class ActorManager
      include AgentManager

      def init
        agent.add_subscriber("agent_actor.#{agent.agent_id}") { |data|
          begin
            request = eval(data)
            handle_request(request)
          rescue => e
            Wakame.log.error(e)
            publish_to('agent_event', Packets::ActorResponse.new(self, request[:token], Actor::STATUS_FAILED, {:message=>e.message, :exclass=>e.class.to_s}).marshal)
          end
        }


      register(Actor::ServiceMonitor.new, '/service_monitor')
      register(Actor::Daemon.new, '/daemon')
      register(Actor::System.new, '/system')
      register(Actor::MySQL.new, '/mysql')
      register(Actor::Deploy.new, '/deploy')
      register(Actor::Monitor.new, '/monitor')
        
      end

      def terminate
      end

      attr_reader :actors

      def initialize()
        @actors = {}
      end
      
      def register(actor, path=nil)
        raise '' unless actor.kind_of?(Wakame::Actor)
        
        if path.nil?
          path = '/' + Util.to_const_path(actor.class.to_s)
        end
        
        if @actors.has_key?(path)
          Wakame.log.error("#{self.class}: Duplicate registration: #{path}")
          raise "Duplicate registration: #{path}"
        end
        
        actor.agent = self.agent
        @actors[path] = actor
      end
      
      def unregister(path)
        @actors.delete(path)
      end
      
      def find_actor(path)
        @actors[path]
      end


      private
      def handle_request(request)
        slash = request[:path].rindex('/') || raise("Invalid request path: #{request[:path]}")
        
        prefix = request[:path][0, slash]
        action = request[:path][slash+1, request[:path].length]

        actor = find_actor(prefix) || raise("Invalid request path: #{request[:path]}")

        EM.defer(proc {
                   begin
                     Wakame.log.debug("#{self.class}: Started to run the actor: #{actor.class}, token=#{request[:token]}")
                     agent.publish_to('agent_event', Packets::ActorResponse.new(agent, request[:token], Actor::STATUS_RUNNING).marshal)
                     if request[:args].nil?
                       actor.send(action)
                     else
                       actor.send(action, *request[:args])
                     end
                     Wakame.log.debug("#{self.class}: Finished to run the actor: #{actor.class}, token=#{request[:token]}")
                     actor.return_value
                   rescue => e
                     Wakame.log.error("#{self.class}: Failed the actor: #{actor.class}, token=#{request[:token]}")
                     Wakame.log.error(e)
                     e
                   end
                 }, proc { |res|
                   status = Actor::STATUS_SUCCESS
                   if res.is_a?(Exception)
                     status = Actor::STATUS_FAILED
                     opts = {:message => res.message, :exclass=>res.class.to_s}
                   else
                     opts = {:return_value=>res}
                   end
                   agent.publish_to('agent_event', Packets::ActorResponse.new(self.agent, request[:token], status, opts).marshal)
                 })
      end
    end
  end
end
