# -*- coding: utf-8 -*-

require 'celluloid'

module Dolphin
  class QueryProcessor
    include Celluloid
    include Dolphin::Util

    def get_notification(id)
      logger :info, "Get notification #{id}"
      notification = Dolphin::Models::Notification.new
      notification.get(id)
    end

    def put_event(event)
      logger :info, "Put event #{event}"
      e = Dolphin::Models::Event.new
      e.put(event)
      e
    end

    def get_event(params)
      e = Dolphin::Models::Event.new
      e.get(params)
    end

    def put_notification(notification)
      logger :info, "Put notification #{notification}"
      notification_id = notification[:id]
      methods = notification[:methods]
      n = Dolphin::Models::Notification.new
      n.put(notification_id, methods)
      n
    end
  end
end