# -*- coding: utf-8 -*-
require 'multi_json'
require 'extlib/blank'

module Dolphin
  module Helpers
    module RequestHelper

      def attach_request_params(request)
        raise "Unsuppoted Content-Type: #{request.env['Content-Type']}" unless request.env['Content-Type'] === 'application/json'
        @params = {}
        @notification_id ||= request.env['X-Notification-Id']
        @message_type ||= request.env['X-Message-Type']
        case request.method
          when "POST"
            v = request.input.to_a[0]
            @params = MultiJson.load(v)
          when "GET"
            @params = parse_query_string(request.env["QUERY_STRING"])
        end
        @params
      end

      def run(request, &blk)
        begin
          attach_request_params(request)
          logger :info, "params #{@params}"
          blk.call
        rescue => e
          logger :error, e.message
          logger :error, e.backtrace
          [400, MultiJson.dump({
            :message => e.message
          })]
        end
      end

      def respond_with(data)
        [200, MultiJson.dump(data)]
      end

      private
      def parse_query_string(query_string)
        params = {}
        unless query_string.blank?
          parts = query_string.split('&')
          parts.collect do |part|
            key, value = part.split('=')
            params.store(key, value)
          end
        end
        params
      end

      def parse_time(time)
        return nil if time.blank? || !time.is_a?(String)
        Time.parse(URI.decode(time)).to_time
      end
    end
  end
end
