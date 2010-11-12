# -*- coding: utf-8 -*-

require 'isono'
require 'eventmachine'

Thread.new { EventMachine.epoll; EventMachine.run }

Signal.trap('EXIT') { EventMachine.stop }

Dcmgr.class_eval {
  def self.messaging
    @messaging_client ||= Isono::MessagingClient.start(conf.amqp_server_uri) do
      node_name 'dcmgr'
      node_instance_id "#{Isono::Util.default_gw_ipaddr}:#{Process.pid}"
    end
  end
}
