# -*- coding: utf-8 -*-

require 'socket'
require 'isono'
require 'dcmgr/messaging_client'

Dcmgr.class_eval {
  def self.messaging
    @messaging_client || set_messging_client
  end

  def self.set_messging_client
    raise "reactor is not running" unless EM.reactor_running?

    amqp_server_uri = Dcmgr::Configurations.dcmgr.amqp_server_uri
    @messaging_client = Dcmgr::MessagingClient.start(amqp_server_uri) do
      node_name 'dcmgr'
      node_instance_id "#{Socket.gethostname}:#{Process.pid}"
    end

    raise("Connetion failed: #{amqp_server_uri}") unless @messaging_client

    @messaging_client
  end
}
