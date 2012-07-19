# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'amqp'
require 'base64'
require 'eventmachine'

module Sinatra
  module PublishMessage
    module HelperMethods

      def publish(message, params)
        EM.schedule do
          conn = Dcmgr.messaging.amqp_client
          channel = AMQP::Channel.new(conn)
          ex = channel.topic(params[:topic_name], params[:queue_options])
          begin
            channel = AMQP::Channel.new(conn)
            queue = AMQP::Queue.new(channel, params[:queue_name], :exclusive => false, :auto_delete => true)
            queue.bind(ex)
            queue.publish(message(params[:name], message))
            #queue.publish(message)
          rescue Exception => e
            logger.error(e)
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
      def message(name, contents)
       #[Base64.encode64(name),Base64.encode64(contents)].join(',')
       boundary = "\n \n"
       [Base64.encode64(name).chomp,Base64.encode64(contents).chomp].join(boundary)
      end
    end

    def self.registered(app)
      app.helpers HelperMethods
    end

  end
end
