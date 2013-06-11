# -*- coding: utf-8 -*-

require 'multi_json'

module Dolphin
  module Models
    class Notification < Base
      def get(id)
        res = db.get('notifications', id.to_s)
        MultiJson.load(res['methods'])
      end

      def put(id, methods)
        column_name = 'methods'
        row_key = id.to_s
        value = MultiJson.dump(methods)

        db.insert('notifications', row_key, {column_name => value})
      end

      def delete(id)
        db.remove('notifications', id)
      end
    end
  end
end
