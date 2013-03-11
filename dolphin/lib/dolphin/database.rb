# -*- coding: utf-8 -*-

require 'cassandra/1.1'

module Thrift
  class FramedTransport < BaseTransport
    def write(buf,sz=nil)
      if !['US-ASCII', 'ASCII-8BIT'].include?(buf.encoding.to_s)
        buf = buf.unpack("a*").first
      end
      return @transport.write(buf) unless @write

      @wbuf << (sz ? buf[0...sz] : buf)
    end
  end
end

module Dolphin
  module DataBase

    def db
      Dolphin::DataBase.create(Dolphin.settings['database']['adapter'].to_sym, {
        :class => self
      }).connect
    end

    def self.create(adapter, options)
      case adapter
        when :cassandra
          # TODO: more better code
          column_family = options[:class].class.name.split('::')[2].downcase + 's'
          uri = [Dolphin.settings['database']['host'], Dolphin.settings['database']['port']].join(':')
          klass = Dolphin::DataBase::Cassandra
          config = {
            :keyspace => Dolphin::DataBase::Cassandra::KEYSPACE,
            :cf => column_family,
            :uri => uri
          }
        else
          raise NotImplementedError
      end
      klass.new(config)
    end

    class ConncetionBase
      def connect
        raise NotImplementedError
      end

      def path
        raise NotImplementedError
      end
    end

    class Cassandra < ConncetionBase
      PATH_SEPARATOR = ':'.freeze
      KEYSPACE = 'dolphin'.freeze
      def column_family

      end

      def initialize(config)
        @keyspace = config[:keyspace]
        @cf = config[:cf]
        @uri = config[:uri]
      end

      def connect
        @connection ||= ::Cassandra.new(@keyspace, @uri)
      end
    end
  end
end
