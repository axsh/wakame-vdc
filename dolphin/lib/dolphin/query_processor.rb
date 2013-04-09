# -*- coding: utf-8 -*-

require 'celluloid'

module Dolphin
  class QueryProcessor
    include Celluloid
    include Dolphin::Util

    def get_notification(id)
      logger :info, "Get notification #{id}"
      send('notification', 'get', id)
    end

    def put_event(event)
      logger :info, "Put event #{event}"
      send('event', 'put', event)
    end

    def get_event(params)
      send('event', 'get', params)
    end

    def put_notification(notification)
      logger :info, notification
      notification_id = notification[:id]
      methods = notification[:methods]
      send('notification', 'put', notification_id, methods)
    end

    private
    def send(model_name, method, *args)
      begin
        klass = Dolphin::Models.const_get(model_name.capitalize)
        k = klass.new
        results = k.__send__(method, *args)
      rescue => e
        logger :error, e
        false
      end
    end
  end
end