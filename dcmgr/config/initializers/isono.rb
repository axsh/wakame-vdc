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

Dcmgr.class_eval {
  def self.messaging
    @messaging_client || raise("Connetion failed: #{conf.amqp_server_uri}")
  end

  def self.syncronized_message_ready
   if !(@messaging_client && @messaging_client.connected?)
      @messaging_client = Isono::MessagingClient.start(conf.amqp_server_uri) do
        node_name 'dcmgr'
        node_instance_id "#{Isono::Util.default_gw_ipaddr}:#{Process.pid}"
      end
    end
  end
}
