# -*- coding: utf-8 -*-

require 'cassandra/1.1'

module Dcmgr::Models
  module LogStorage

    class Cassandra < Base
      PATH_SEPARATOR = ':'.freeze

      def initialize(config)
        @keyspace = config[:keyspace]
        @cf = config[:cf]
        @uri = config[:uri]
      end

      def connect
        @connection ||= ::Cassandra.new(@keyspace, @uri)
      end

      def timeseries_search(path, time, limit)
        rowkey = timed_slice_path(path, time)
        connect.get(@cf, rowkey, {
          :start => DateTime.parse(time).to_time,
          :count => limit.to_i
        })
      end

      def position_search(path, position_id, limit, config)
        # time convert '2012-01-01 01:00:00' to '2012010101'
        rowkey = timed_slice_path(path, config[:time])
        connect.get(@cf, rowkey, {
          :start => position_id,
          :count => limit.to_i
        })
      end

      def path(account_id, instance_id, application_id)
        @path = [account_id, instance_id, application_id].join(PATH_SEPARATOR)
      end

      def get_keys
        connect.get_range_keys(@cf)
      end

      private
      def timed_slice_path(path, time)
        case time
          when String
            t = DateTime.parse(time)
          else
            raise "Unsupported time format #{time}"
        end
        [path, t.strftime("%Y%m%d%H")].join(PATH_SEPARATOR)
      end

    end
  end
end