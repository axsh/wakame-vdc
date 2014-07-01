# -*- coding: utf-8 -*-

require 'isono'
require 'eventmachine'

module Dcmgr
  # @example Sync RPC call with object method.
  # mc = MessagingClient.start
  # puts mc.request('endpoint', 'func1', xxxx, xxxx)
  # puts mc.request('endpoint', 'func2', xxx, xxx)
  #
  # @example Sync RPC call using delegated object
  # mc = MessagingClient.start
  # endpoint = mc.sync_rpc('endpoint')
  # endpoint.func1(xxxx, xxxx)
  # endpoint.func2(xxx, xxx)
  #
  class MessagingClient < Isono::Node
    include Logger
    include Isono

    def self.start(amqp_uri, manifest=nil, &blk)
      node = self.new(manifest, &blk)

      if EventMachine.reactor_thread?
        EventMachine.schedule {
          node.connect(amqp_uri)
        }
      else
        q = ::Queue.new
        EventMachine.schedule {
          node.connect(amqp_uri) { |type|
            q << type
          }
        }
        case q.deq
        when :success
        when :error
          raise "Connection failed: #{amqp_uri}"
        end
      end

      node
    end

    def stop
      if connected?
        close {
          EventMachine.schedule {
            EventMachine.stop
          }
        }
      end
    end

    def initialize(m=nil, &blk)
      m ||= Isono::Manifest.new(Dir.pwd) {
        node_name 'dcmgr'
        node_instance_id Util.gen_id

        load_module Isono::NodeModules::EventChannel
        load_module Isono::NodeModules::RpcChannel
        load_module Isono::NodeModules::JobChannel
      }
      m.instance_eval(&blk) if blk
      super(m)
    end

    class RpcSyncDelegator
      attr_reader :endpoint

      def initialize(rpc, endpoint, opts={})
        @rpc = rpc
        @endpoint = endpoint
        @opts = {:timeout=>0.0, :oneshot=>false}.merge(opts)
      end

      private
      def method_missing(m, *args)
        if @opts[:oneshot]
          oneshot_request(m, *args)
        else
          normal_request(m, *args)
        end
      end

      def oneshot_request(m, *args)
        @rpc.request(@endpoint, m, *args) { |req|
          req.oneshot = true
        }
      end

      def normal_request(m, *args)
        @rpc.request(@endpoint, m, *args)
      end
    end

    def sync_rpc(endpoint, opts={})
      rpc = Isono::NodeModules::RpcChannel.new(self)
      RpcSyncDelegator.new(rpc, endpoint, opts)
    end

    def request(endpoint, key, *args, &blk)
      rpc = Isono::NodeModules::RpcChannel.new(self)
      rpc.request(endpoint, key, *args, &blk)
    end

    def submit(job_endpoint, key, *args)
      Isono::NodeModules::JobChannel.new(self).submit(job_endpoint, key, *args)
    end

    def job_run(job_endpoint, key, *args)
      Isono::NodeModules::JobChannel.new(self).run(job_endpoint, key, *args)
    end

    def event_publish(evname, opts={})
      Isono::NodeModules::EventChannel.new(self).publish(evname, opts)
    end

  end
end
