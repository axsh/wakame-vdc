# -*- coding: utf-8 -*-

require 'multi_json'

module Dolphin
  module Models
    class Event < Base
      def put(event)

        notification_id = event[:notification_id]
        column_name = SimpleUUID::UUID.new(Time.now).to_guid
        time = Time.now.strftime("%Y%m%d%m%d")
        row_key = [notification_id, time].join(':')
        value = MultiJson.dump(event[:messages])

        db.insert('events', row_key, {column_name => value})
      end
    end
  end
end
