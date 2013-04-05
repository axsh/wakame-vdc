require 'thrift'

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

module Fluent
  class WakameVdcLogStore < BufferedOutput
    Fluent::Plugin.register_output('wakame_vdc_logstore', self)

    def initialize
      super
      require 'cassandra/1.1'
      require 'msgpack'
    end

    def configure(conf)
      super

      raise ConfigError, "'Keyspace' parameter is required on cassandra output"   unless @keyspace = conf['keyspace']
      raise ConfigError, "'ColumnFamily' parameter is required on cassandra output"   unless @columnfamily = conf['columnfamily']

      @host = conf.has_key?('host') ? conf['host'] : 'localhost'
      @port = conf.has_key?('port') ? conf['port'] : 9160
    end

    def start
      super
      @connection = Cassandra.new(@keyspace, @host + ':' + @port )
    end

    def shutdown
      super
    end

    def format(tag, time,record)
      unless record.has_key?('x_wakame_label')
        record['x_wakame_label'] = tag
      end
      record.to_msgpack
    end

    def write(chunk)
      chunk.msgpack_each  { |record|

         instance_id = ''
         account_id = ''
         label = ''

         record.each{|r|
           case r[0]
             when 'x_wakame_instance_id'
               instance_id = r[1]
             when 'x_wakame_account_id'
               account_id = r[1]
             when 'x_wakame_label'
               label = r[1]
           end
         }

         time = Time.now.strftime('%Y%m%d%H')
         rowkey = [account_id, instance_id, label, time].join(":")
         column_name = SimpleUUID::UUID.new(Time.now)

         @connection.insert(
           @columnfamily,
           rowkey,
           {column_name => record['message']}
         )
      }
    end
  end
end
