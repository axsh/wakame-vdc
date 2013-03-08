# -*- coding: utf-8 -*-

require 'multi_json'

module Dolphin
  module Models
    class Event < Base
      COLUMN_FAMILY = 'events'.freeze
      ROW_KEY = 'history'.freeze

      def get(params)
        options = {
          :start => params[:start_time],
          :count => params[:count]
        }

        db.get(COLUMN_FAMILY, ROW_KEY, options).collect do |event| {
          'id' => event[0].to_guid,
          'event' => MultiJson.load(event[1]),
          'created_at' => SimpleUUID::UUID.new(event[0].to_guid).to_time.iso8601
        }
        end
      end

      def put(event)
        column_name = SimpleUUID::UUID.new(Time.now).to_guid
        value = MultiJson.dump(event[:messages])
        db.insert(COLUMN_FAMILY, ROW_KEY, {column_name => value})
      end
    end
  end
end
