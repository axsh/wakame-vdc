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
    include Dolphin::Util

    def db
      con = Dolphin::DataBase.create(Dolphin.settings['database']['adapter'].to_sym, {
        :class => self
      }).connect

      if con.nil?
        raise 'Connection to database failed'
      else
        con
      end
    end

    def hosts
      Dolphin.settings['database']['hosts']
    end

    def self.create(adapter, options)

      config = {
        :hosts => Dolphin.settings['database']['hosts'],
        :port => Dolphin.settings['database']['port'],
        :max_retry_count => Dolphin.settings['database']['max_retry_count'].to_i,
        :retry_interval => Dolphin.settings['database']['retry_interval'].to_i
      }

      case adapter
        when :cassandra
          # TODO: more better code
          column_family = options[:class].class.name.split('::')[2].downcase + 's'
          klass = Dolphin::DataBase::Cassandra
          config.merge!({
            :keyspace => Dolphin::DataBase::Cassandra::KEYSPACE,
            :cf => column_family
          })
        else
          raise NotImplementedError
      end
      klass.new(config)
    end

    class ConncetionBase
      include Dolphin::Util

      def connect
        raise NotImplementedError
      end

      def path
        raise NotImplementedError
      end
    end

    class Cassandra < ConncetionBase

      class UnAvailableNodeException < Exception; end

      PATH_SEPARATOR = ':'.freeze
      KEYSPACE = 'dolphin'.freeze

      def initialize(config)
        @keyspace = config[:keyspace]
        @cf = config[:cf]
        raise "database hosts is blank" if config[:hosts].empty?
        @hosts = config[:hosts].split(',')
        @port = config[:port]
        @max_retry_count = config[:max_retry_count]
        @retry_interval = config[:retry_interval]
        @retry_count = 0
      end

      def connect
        begin
          if @connection.nil?
            @connection = ::Cassandra.new(@keyspace, servers)

            # test connecting..
            @connection.ring
            return @connection
          end
        rescue ThriftClient::NoServersAvailable => e
          logger :error, e
          if @retry_count < @max_retry_count
            @connection = nil
            @retry_count += 1
            logger :error, "retry connection..#{@retry_count}"
            sleep @retry_interval
            retry
          end
        rescue UnAvailableNodeException => e
          logger :error, e
        rescue CassandraThrift::InvalidRequestException => e
          logger :error, e
        end
        nil
      end

      private
      def servers
        @hosts.collect{|host| "#{host}:#{@port}"}
      end
    end
  end
end
