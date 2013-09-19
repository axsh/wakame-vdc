# -*- coding: utf-8 -*-
require 'multi_json'

module DolphinClient
  class Notification
    class << self
      def get(notification_id)
        client = API.new
        client.headers.update "X-Notification-Id" => notification_id
        response = client.get_notifications{|request|
          request.uri = DolphinClient.domain + request.uri.to_s
        }.perform
        client.finish(response)
      end
    end
  end
end
