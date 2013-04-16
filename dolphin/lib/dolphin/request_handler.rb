# -*- coding: utf-8 -*-

require 'reel/app'
require 'extlib/blank'

module Dolphin
  class RequestHandler
    include Reel::App
    include Dolphin::Util
    include Dolphin::Helpers::RequestHelper

    def initialize(host, port)

      # TODO: Fix Celluloid.logger loading order.
      logger :info, "Load settings in #{Dolphin.config}"

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
            status, headers_or_body, body = call Rack::MockRequest.env_for(request.url, options)
            connection.respond status_symbol(status), headers_or_body, body.to_s
          rescue => e
            logger :error, e
            break
          end
        end
      end
      logger :info, "Running on ruby #{RUBY_VERSION} with selected #{Celluloid::task_class}"
      logger :info, "Listening on http://#{host}:#{port}"
      @server
    end

    post '/events' do |request|
      run(request) do
        raise 'Not found notification_id' unless @notification_id
        raise 'Nothing parameters.' if @params.blank?

        event = {}
        event[:notification_id] = @notification_id
        event[:message_type] = @message_type
        event[:messages] = @params

        events = worker.future.put_event(event)

        # always success because put_event is async action.
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
        params[:start_id] = @params['start_id'] unless @params['start_id'].blank?

        events = worker.get_event(params)
        raise events.message if events.fail?

        response_params = {
          :results => events.message,
          :message => 'OK'
        }
        response_params[:start_time] = @params['start_time'] unless @params['start_time'].blank?
        respond_with response_params
      end
    end

    post '/notifications' do |request|
      run(request) do
        raise 'Nothing parameters.' if @params.blank?

        unsupported_sender_types = @params.keys - Sender::TYPES
        raise "Unsuppoted sender types: #{unsupported_sender_types.join(',')}" unless unsupported_sender_types.blank?

        notification = {}
        notification[:id] = @notification_id
        notification[:methods] = @params
        result = worker.put_notification(notification)
        raise result.message if result.fail?

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
