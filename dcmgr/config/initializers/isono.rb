# -*- coding: utf-8 -*-

require 'isono'
require 'eventmachine'

Signal.trap('EXIT') { EventMachine.stop }

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if EventMachine.reactor_running?
      EventMachine.stop
      Dcmgr.class_eval {
        @messaging_client = nil
      }
    end
    Thread.new { EventMachine.epoll; EventMachine.run; }
    
    if forked
     else
    end
  end
else
  EventMachine.stop if EventMachine.reactor_running?
  Thread.new { EventMachine.epoll; EventMachine.run; }
end

Dcmgr.class_eval {
  def self.messaging
    @messaging_client ||= Isono::MessagingClient.start(conf.amqp_server_uri) do
      node_name 'dcmgr'
      node_instance_id "#{Isono::Util.default_gw_ipaddr}:#{Process.pid}"
    end
  end
}
