# -*- coding: utf-8 -*-

require 'reel/app'
require 'extlib/blank'

module Dolphin
  class RequestHandler
    include Reel::App
    include Dolphin::Util
    include Dolphin::Helpers::RequestHelper

    def initialize(host, port)
      @server = Reel::Server.supervise_as(:reques_handler, host, port) do |connection|
        while request = connection.request
          options = {
            :method => request.method,
            :input => request.body
          }
          options.merge!(request.headers)
          status, headers, body = call Rack::MockRequest.env_for(request.url, options)
          connection.respond status_symbol(status), headers, body.to_s
        end
      end
      logger :info, "Listening on http://#{host}:#{port}"
    end

    post '/events' do |request|
      attach_request_params(request)
      logger :info, "params #{@params}"

      event = {}
      event[:notification_id] = @notification_id
      event[:message_type] = @message_type
      event[:messages] = @params

      worker.future.put_event(event)
      [200, {}, "success!\n"]
    end

    get '/events' do |request|
      attach_request_params(request)
      logger :info, "params #{@params}"

      [200, {}, "success!\n"]
    end

    post '/notifications' do |request|
      attach_request_params(request)
      logger :info, "params #{@params}"

      notification = {}
      notification[:id] = @notification_id
      notification[:methods] = @params
      worker.future.put_notification(notification)
      [200, {}, "success!\n"]
    end

    private
    def worker
      Celluloid::Actor[:workers]
    end
  end
end