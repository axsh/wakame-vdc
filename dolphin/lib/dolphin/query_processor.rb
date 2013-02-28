# -*- coding: utf-8 -*-

require 'celluloid'

module Dolphin
  class QueryProcessor
    include Celluloid
    include Dolphin::Util

    def get_notification(id)
      logger :debug, "Get notification #{id}"
      notification = Dolphin::Models::Notification.new
      notification.get(id)
    end

    def put_event(event)
      logger :debug, "Put event #{event}"
      e = Dolphin::Models::Event.new
      e.put(event)
      e
    end

    def put_notification(notification)
      logger :debug, "Put notification #{notification}"
      notification_id = notification[:id]
      methods = notification[:methods]
      n = Dolphin::Models::Notification.new
      n.put(notification_id, methods)
      n
    end
  end
end