# -*- coding: utf-8 -*-
require 'multi_json'

module DolphinClient
  class Event
    class << self
      def post(data)
        client = API.new

        if data[:notification_id]
          client.headers.update "X-Notification-Id" => data[:notification_id]
        end

        if data[:message_type]
          client.headers.update "X-Message-Type" => data[:message_type]
        end

        response = client.post_events {|request|
          request.uri = DolphinClient.domain + request.uri.to_s
          request.json data[:params]
        }.perform
        client.finish(response)
      end

      def get
        client = API.new
        response = client.get_events{|request|
          request.uri = DolphinClient.domain + request.uri.to_s
        }.perform
        client.finish(response)
      end
    end
  end
end
