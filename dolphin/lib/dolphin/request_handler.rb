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

        event = worker.future.put_event(event).value
        raise event.message if event.fail?

        response_params = {
          :message => 'OK'
        }
        respond_with response_params
      end
    end

    get '/events' do |request|
      run(request) do
        limit = @params['limit'].blank? ? 100 : @params['limit'].to_i

        params = {}
        params[:count] = limit
        params[:start_time] = parse_time(@params['start_time']) unless @params['start_time'].blank?

        events = worker.get_event(params).value

        response_params = {
          :results => events,
          :message => 'OK'
        }
        response_params[:start_time] = @params['start_time'] unless @params['start_time'].blank?
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