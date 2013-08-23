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

        client.post_events {|request|
          request.uri = DolphinClient.domain + request.uri.to_s
          request.json data[:params]
        }.perform
      end

      def get
        client = API.new
        response = client.get_events{|request|
          request.uri = DolphinClient.domain + request.uri.to_s
        }.perform
        MultiJson.load(response.body) if response.success?
      end
    end
  end
end
