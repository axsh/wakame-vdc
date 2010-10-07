# -*- coding: utf-8 -*-

require 'isono'
require 'eventmachine'

Thread.new { EventMachine.epoll; EventMachine.run }

Dcmgr.class_eval {
  def self.messaging
    @messaging_client ||= Isono::MessagingClient.start(conf.amqp_server_uri) do
      node_name 'dcmgr'
      node_instance_id "#{Process.pid}"
    end
  end
}
