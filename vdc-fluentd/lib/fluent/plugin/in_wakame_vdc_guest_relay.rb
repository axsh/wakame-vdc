# -*- coding: utf-8 -*-

require 'ipaddr'
require 'yaml'

module Fluent

  class WakemeVdcGuestRelay < ForwardInput
    Plugin.register_input('wakame_vdc_guest_relay', self)

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
      send_data[@prefix_key + 'ipaddr'] = instance_ipv4

      # Merge data
      es = MessagePackEventStream.new(entries, @cached_unpacker)
      mes = MultiEventStream.new
      es.entries.each{|e| mes.add(e[0], e[1].merge(send_data)) }
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

      instance_ids = []
      search_pattern = @instances_path + 'i-*'
      Dir.glob(search_pattern) {|path|
        instance_ids << path.sub(@instances_path, '')
      }
      instance_ids.each {|instance_id|
        meta_data_file = "#{@instances_path}#{instance_id}/metadata.yml"
        meta_data = load_meta_data(meta_data_file)
        if !meta_data.empty?
          instance_ipv4 = meta_data['local-ipv4']
          @instances[instance_ipv4] = {}
          @instances[instance_ipv4][:instance_id] = instance_id
          @instances[instance_ipv4][:account_id] = meta_data['x-account-id']
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

    private
    def load_meta_data(meta_data_file)
      $log.debug meta_data_file
      meta_data  = {}
      begin
        if File.exists? meta_data_file
          meta_data = YAML.load(File.read(meta_data_file, :encoding => Encoding::UTF_8))
        else
          $log.warn "No suche file #{meta_data_file}"
        end
      rescue => e
        raise e
      end
      meta_data
    end


  end
end
