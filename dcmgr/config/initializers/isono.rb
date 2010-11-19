# -*- coding: utf-8 -*-

require 'isono'
require 'eventmachine'

Signal.trap('EXIT') { EventMachine.stop }

if defined?(PhusionPassenger)
  if PhusionPassenger::VERSION_STRING =~ /^3\.0\./
   blk = proc { |forked|
      if EventMachine.reactor_running?
        EventMachine.stop
        Dcmgr.class_eval {
          @messaging_client = nil
        }
      end
      Thread.new { EventMachine.epoll; EventMachine.run; }
    }
  else
   blk = proc {
      if EventMachine.reactor_running?
        EventMachine.stop
        Dcmgr.class_eval {
          @messaging_client = nil
        }
      end
      Thread.new { EventMachine.epoll; EventMachine.run; }
    }
  end
  PhusionPassenger.on_event(:starting_worker_process, &blk)
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
