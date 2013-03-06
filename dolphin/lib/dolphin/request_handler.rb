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
          begin
            logger :info, {
              :host => request.headers["Host"],
              :user_agent => request.headers["User-Agent"]
            }
            options = {
              :method => request.method,
              :input => request.body
            }
            options.merge!(request.headers)
            status, headers, body = call Rack::MockRequest.env_for(request.url, options)
            connection.respond status_symbol(status), headers, body.to_s
          rescue => e
            logger :error, e
            break
          end
        end
      end
      logger :info, "Listening on http://#{host}:#{port}"
    end

    post '/events' do |request|
      run(request) do
        raise 'Not found notification_id' unless @notification_id
        raise 'Nothing parameters.' if @params.blank?

        event = {}
        event[:notification_id] = @notification_id
        event[:message_type] = @message_type
        event[:messages] = @params

        worker.future.put_event(event)
        response_params = {
          :message => 'OK'
        }
        respond_with response_params
      end
    end

    get '/events' do |request|
      run(request) do
        start = @params['start'].to_i || 0
        limit = @params['limit'].to_i || 100

        params = {}
        params[:start] = start
        params[:count] = limit
        events = worker.get_event(params).value

        response_params = {
          :start => start,
          :results => events,
          :message => 'OK'
        }
        respond_with response_params
      end
    end

    post '/notifications' do |request|
      run(request) do
        raise 'Nothing parameters.' if @params.blank?

        notification = {}
        notification[:id] = @notification_id
        notification[:methods] = @params
        worker.future.put_notification(notification)
        response_params = {
          :message => 'OK'
        }
        respond_with response_params
      end
    end

    private
    def worker
      Celluloid::Actor[:workers]
    end
  end
end