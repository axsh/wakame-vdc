

module Wakame
  module QueueDeclare
    def self.included(klass)
      klass.class_eval {
        define_exchange 'registry', :fanout
        define_exchange 'ping', :fanout
        define_exchange 'agent_command', :topic
        define_exchange 'agent_event', :fanout
      }
    end
  end
end
