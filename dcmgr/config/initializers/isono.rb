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

if defined?(PhusionPassenger)
  if PhusionPassenger::VERSION_STRING =~ /^3\.0\./
    blk = proc { |forked|
      restart_reactor_and_messaging_client
    }
  else
    blk = proc {
      restart_reactor_and_messaging_client
    }
  end
  PhusionPassenger.on_event(:starting_worker_process, &blk)
else
  restart_reactor_and_messaging_client
end

Dcmgr.class_eval {
  def self.messaging
    @messaging_client ||= Isono::MessagingClient.start(conf.amqp_server_uri) do
      node_name 'dcmgr'
      node_instance_id "#{Isono::Util.default_gw_ipaddr}:#{Process.pid}"
    end
  end
}
