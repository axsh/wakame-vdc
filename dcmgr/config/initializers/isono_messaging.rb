# -*- coding: utf-8 -*-

require 'socket'
require 'isono'
require 'dcmgr/messaging_client'

Dcmgr.class_eval {
  def self.messaging
    @messaging_client ||= set_messging_client || raise("Connetion failed: #{conf.amqp_server_uri}")
  end

  def self.set_messging_client
    raise "reactor is not running" unless EM.reactor_running?
    @messaging_client = Dcmgr::MessagingClient.start(conf.amqp_server_uri) do
      node_name 'dcmgr'
      node_instance_id "#{Socket.gethostname}:#{Process.pid}"
    end
  end
}
