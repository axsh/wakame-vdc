# -*- coding: utf-8 -*-

module Dcmgr::Models
  module LogStorage

    def self.create(storage_type, *args)
      case storage_type
        when :cassandra
          model = Dcmgr::Models::LogStorage::Cassandra
        else
          raise NotImplementedError
      end
      model.new(*args)
    end

    class Base

      def connect
        raise NotImplementedError
      end

      def path
        raise NotImplementedError
      end
    end

  end
end