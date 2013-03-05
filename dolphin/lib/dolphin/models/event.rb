# -*- coding: utf-8 -*-

require 'multi_json'

module Dolphin
  module Models
    class Event < Base
      def get(notification_id, options = {})
        row_key = notification_id
        options = {
          :count => options[:count]
        }

        db.get('events', row_key, options).collect do |event|
        {
          'event_id' => event[0].to_guid,
          'event' => MultiJson.load(event[1])
        }
        end
      end

      def put(event)

        notification_id = event[:notification_id]
        column_name = SimpleUUID::UUID.new(Time.now).to_guid
        row_key = notification_id
        value = MultiJson.dump(event[:messages])

        db.insert('events', row_key, {column_name => value})
      end
    end
  end
end
