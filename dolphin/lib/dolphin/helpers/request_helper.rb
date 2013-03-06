# -*- coding: utf-8 -*-
require 'multi_json'

module Dolphin
  module Helpers
    module RequestHelper

      def attach_request_params(request)
        raise 'Unsuppoted Content-Type' unless request.env['Content-Type'] === 'application/json'
        @params = {}
        @notification_id ||= request.env['X-Notification-Id']
        @message_type ||= request.env['X-Message-Type']
        case request.method
          when "POST"
            v = request.input.to_a[0]
            @params = MultiJson.load(v)
          when "GET"
            @params = request.path.to_hash
        end
        @params
      end

      def run(request, &blk)
        attach_request_params(request)
        logger :info, "params #{@params}"
        begin
          blk.call
        rescue => e
          puts e.backtrace
          [400, MultiJson.dump({
            'message' => e.message
          })]
        end
      end

      def respond_with(data)
        [200, MultiJson.dump(data)]
      end
    end
  end
end