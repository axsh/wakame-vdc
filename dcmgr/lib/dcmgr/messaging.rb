#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'amqp'
require 'base64'
require 'eventmachine'

module Dcmgr
  module Messaging
    MESSAGE_BOUNDARY="\n \n".freeze

    def self.publish(message, params)
      EM.schedule do
        amqp_channel do
          @channel ||= AMQP::Channel.new(@amqp_connection)
          ex = @channel.topic(params[:topic_name], params[:queue_options])
          begin
            queue = AMQP::Queue.new(@channel, params[:queue_name], :exclusive => false, :auto_delete => true)
            queue.bind(ex)
            queue.publish(message(params[:name], message))
          rescue Exception => e
            logger.error(e)
          end
        end
      end
    end

    private
    # Encode:
    # [Base64.encode64('foo').chomp,Base64.encode64('bar').chomp].join(boundary)
    # > Zm9v\n \nYmFy
    #
    # Decode:
    # echo -e 'Zm9v\n \nYmFy' | sed -n '1,/^ $/p'| openssl enc -d -base64
    # > foo
    # echo -e 'Zm9v\n \nYmFy' | sed '1,/^ $/d'| openssl enc -d -base64
    # > bar
    #
    def self.message(name, contents)
     [Base64.encode64(name).chomp,Base64.encode64(contents).chomp].join(MESSAGE_BOUNDARY)
    end

    def self.amqp_channel(&blk)
      if @amqp_connection.nil?
        uri = AMQP::Client.parse_connection_uri(Dcmgr.conf.amqp_server_uri)
        default = ::AMQP.settings
        opts = {:host => uri['host'] || default[:host],
                :port => uri['port'] || default[:port],
                :vhost => uri['vhost'] || default[:vhost],
                :user => uri['user'] || default[:user],
                :pass => uri['password'] ||default[:pass]
        }
        @amqp_connection = AMQP.connect(opts)
      end

      if @amqp_connection.connected?
        blk.call
      else
        @amqp_connection.callback &blk
      end
    end
  end
end
