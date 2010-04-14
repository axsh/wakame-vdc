#!/usr/bin/ruby

require 'mutex_m'

require 'eventmachine'
require 'ext/eventmachine'
require 'amqp'
require 'mq'

module Wakame
  module AMQPClient

    def self.included(klass)
      klass.extend(ClassMethods)
      klass.class_eval {
      }
    end
    
    module ClassMethods
      attr_reader :defered_setup_calls


      def instance
        @instance
      end

      def start(*opts)
        new_instance = proc {
          if @instance.nil?
            @instance = new(*opts)
            @instance.connect(*opts) do
              @instance.init
            end
          end
          @instance
        }
        
        if EM.reactor_running?
          return new_instance.call
        else
          EM.run new_instance
        end
      end
      
      
      def stop(&blk)
        #EM.add_timer(1){
        EM.next_tick {
          end_proc = proc {
            EventDispatcher.reset

            unless blk.nil?
              blk.call
            end
            EM.stop
          }

          catch(:nop) {
          if @instance.nil?
            end_proc.call
            throw :nop
          end
            
          begin
            unless @instance.amqp_client.nil?
              @instance.close { end_proc.call }
            else
              end_proc.call
            end
          ensure
            @instance = nil
          end
          }
        }
      end
      
      def amq
        Thread.current[:mq]
      end

      def publish_to(*args)
        self.instance.publish_to(*args)
      end

      def add_subscriber(*args)
        self.instance.add_subscriber(*args)
      end

      def define_exchange(name, type=:fanout)
        def_ex = proc { |inst|
          inst.amq.__send__(type, name)
        }

        (@defered_setup_calls ||= []) << def_ex
        
        #if !@instance.nil? && @instance.connected?
        #  def_ex.call(@instance)
        #end
      end
      
      def define_queue(name, exchange_name, opts={})
        def_q = proc { |inst|
          inst.define_queue(name, exchange_name, opts)
        }

        (@defered_setup_calls ||= []) << def_q

        #if !@instance.nil? && @instance.connected?
        #  def_q.call(@instance)
        #end
      end

    end

    attr_reader :mq, :amqp_client
    
    def amqp_server_uri
      raise "The connection is not established yet." unless @amqp_client && connected?

      URI::AMQP.build(:host => @amqp_client.settings[:host],
                      :port => @amqp_client.settings[:port],
                      :path => @amqp_client.settings[:vhost]
                      )
    end

    def connect(*args)
      close() unless connected?
      @amqp_client = AMQP.connect(*args)
      @amqp_client.instance_eval {
        def settings
          @settings
        end
      }
      @mq = Thread.current[:mq] = MQ.new(@amqp_client)

      run_defered_callbacks
      yield if block_given?
    end

    def connected?
      !@amqp_client.nil?
    end

    def amq
      raise 'AMQP connection is not established yet' if Thread.current[:mq].nil?
      Thread.current[:mq]
    end

    def cleanup
    end

    def close(&blk)
      closing_proc = proc {
        begin
          cleanup
          yield if block_given?
        ensure
          @amqp_client = nil
          @mq = Thread.current[:mq] = nil
        end
      }

      @amqp_client.close {
        closing_proc.call
      } unless @amqp_client.nil?
    end

    #
    # When you want to broadcast the data to all bound queues:
    #  publish_to('exchange name', 'data')
    #  publish_to('exchange name', '*', 'data')
    # When you want to send the data to keyed  queue(s):
    #  publish_to('exchange name', 'group.1', 'data')
    def publish_to(name, *args)
      publish_proc = proc {
        ex = amq.exchanges[name] || raise("Undefined exchange name : #{name}")
        case ex.type
        when :topic
          if args.size == 1
            key = '*'
            data = args[0]
          else
            key = args[0].to_s
            data = args[1]
          end
        else
          data = args[0]
        end
        ex.publish(data, :key=>key)
      }

      if Thread.current[:mq].nil?
        EM.next_tick { publish_proc.call }
      else
        publish_proc.call
      end
    end

    def define_queue(name, exchange_name, opts={})
      name = instance_eval('"' + name.gsub(/%\{/, '#{') + '"')
      opts.each { |k,v|
        if v.is_a? String
          opts[k] = instance_eval('"' + v.gsub(/%\{/, '#{') + '"')
        end
      }

      @queue_subscribers ||= {}

      q = amq.queue(name, opts)
      q.bind( exchange_name, opts ).subscribe {|data|
        unless queue_subscribers[name].nil?
          queue_subscribers[name].each { |p|
            p.call(data)
          }
        end
      }
    end

    attr_reader :queue_subscribers

    def add_subscriber(queue_name, &blk)
      # @mq object can be used here as it is just for checing the member of defined queues.
      raise "Undefined queue name : #{queue_name}" unless @mq.queues.has_key?(queue_name)
      EM.barrier {
        @queue_subscribers ||= {}
        @queue_subscribers[queue_name] ||= []
        
        @queue_subscribers[queue_name] << blk
      }
    end

    private
    def run_defered_callbacks
      self.class.defered_setup_calls.each { |p|
        p.call(self)
      }
    end

  end
end
