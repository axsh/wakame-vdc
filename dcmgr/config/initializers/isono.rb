# -*- coding: utf-8 -*-

require 'isono'
require 'eventmachine'

Signal.trap('EXIT') { EventMachine.stop }

def restart_reactor_and_messaging_client
  if EventMachine.reactor_running?
    EventMachine.stop
    Dcmgr.class_eval {
      @messaging_client = nil
    }
  end
  Thread.new { EventMachine.epoll; EventMachine.run; }
end

restart_reactor_and_messaging_client

Dcmgr.run_initializers('isono_messaging')
Dcmgr.class_eval {
  def self.syncronized_message_ready
    if !(@messaging_client && @messaging_client.connected?)
      set_messging_client
    end
  end
}
