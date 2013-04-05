# -*- coding: utf-8 -*-

require 'ipaddr'

module Fluent

  class WakemeVdcGuestRelay < ForwardInput
    Plugin.register_input('wakame_vdc_guest_relay', self)

    SEARCH_KEYS = ['local-ipv4', 'x-account-id'].freeze

    LOCAL_LABEL = 'wakame_vdc'.freeze
    INVALID_LABEL = 'invalid'.freeze

    FORWARD_TAG = 'wakame-logger'.freeze

    SYSTEM_ACCOUNT_ID = 'a-00000000'.freeze
    SYSTEM_NODE_ID = 'none'.freeze

    config_param :instances_path, :string
    config_param :label, :string, :default => ''
    config_param :prefix_key, :default => 'x_wakame_'

    attr_accessor :instances

    def initialize
      super
      @instances = {}
    end

    def listen
      $log.info "listening fluent socket on #{@bind}:#{@port}"
      Coolio::TCPServer.new(@bind, @port, MessageHandler, method(:on_message))
    end

    protected

    def on_message(msg)
      $log.debug broker.instance_ip
      $log.debug broker.host_ip

      # Replace tag
      tag = FORWARD_TAG

      label = msg[0]
      entries = msg[1]
      instance_ipv4 = broker.instance_ip

      if is_local?
        instance_id = SYSTEM_NODE_ID
        account_id = SYSTEM_ACCOUNT_ID
      else

        unless has_instance?(instance_ipv4)
          build_instances_mapping_table
        end
        instance_id = @instances[instance_ipv4][:instance_id]
        account_id = @instances[instance_ipv4][:account_id]
      end

      # Added identify instance
      send_data = {}
      send_data[@prefix_key + 'instance_id'] = instance_id
      send_data[@prefix_key + 'account_id'] = account_id
      send_data[@prefix_key + 'label'] = label

      # Merge data
      es = MessagePackEventStream.new(entries, @cached_unpacker)
      mes = MultiEventStream.new
      es.entries.each{|e| mes.add(Time.now.to_i, e[1].merge(send_data)) }
      es = mes
      Engine.emit_stream(tag, es)
    end

    def has_instance?(instance_ipv4)
      @instances.has_key? instance_ipv4
    end

    def broker
      watchers = @loop.instance_variable_get(:@watchers)
      watchers.keys[2].instance_variable_get(:@coolio_io)
    end

    def is_local?
      broker.instance_ip == broker.host_ip
    end

    def build_instances_mapping_table

      search_path = @instances_path + '*'
      instance_ids = []

      Dir.glob(search_path) {|path|
        instance_ids << path.sub(@instances_path, '')
      }

      instance_ids.each {|instance_id|
        meta_data_path = "#{@instances_path}#{instance_id}/metadata_host/meta-data/"
        meta_data = []
        SEARCH_KEYS.each {|key|
          meta_data_file = "#{meta_data_path}/#{key}"
          if File.exists? meta_data_file
            meta_data << File.read(meta_data_file)
          end
        }

        if !meta_data.empty?
          instance_ipv4 = meta_data[0].chomp!
          @instances[instance_ipv4] = {}
          @instances[instance_ipv4][:instance_id] = instance_id
          @instances[instance_ipv4][:account_id] = meta_data[1].chomp!
        end
      }

    end

    class MessageHandler < Handler
      def initialize(io, on_message)
        super
        @addr = io.addr
        @peeraddr = io.peeraddr
      end

      def host_ip
        @addr[3]
      end

      def instance_ip
        @peeraddr[3]
      end
    end

  end
end
