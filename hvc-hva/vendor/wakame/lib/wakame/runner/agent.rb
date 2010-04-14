#!/usr/bin/ruby

require 'optparse'
require 'amqp'

module Wakame
  module Runner
    class Agent
      include Wakame::Daemonize
      
      def initialize(argv)
        @argv = argv.dup
        
        @options = {
          :amqp_server => URI.parse('amqp://guest@localhost/'),
          :log_file => '/var/log/hva.log',
          :pid_file => '/var/run/hva.pid',
          :daemonize => true
        }
        
        parser.parse! @argv
      end
      
      
      def parser
        @parser ||= OptionParser.new do |opts|
          opts.banner = "Usage: agent [options]"
          
          opts.separator ""
          opts.separator "Agent options:"
          opts.on( "-p", "--pid PIDFILE", "pid file path" ) {|str| @options[:pid_file] = str }
          opts.on( "-s", "--server AMQP_URI", "amqp server" ) {|str|
            begin 
              @options[:amqp_server] = URI.parse(str)
            rescue URI::InvalidURIError => e
              fail "#{e}"
            end
          }
          opts.on("-X", "", "daemonize flag" ) { @options[:daemonize] = false }
          
        end


      end

      
      def run
        %w(QUIT INT TERM).each { |i|
          Signal.trap(i) { Wakame::Agent.stop{ remove_pidfile } }
        }

        opts = ::AMQP.settings.dup
        unless @options[:amqp_server].nil?
          uri = @options[:amqp_server]
          opts[:host] = uri.host
          opts[:port] = uri.port if uri.port
          opts[:vhost] = uri.vhost if uri.vhost
          opts[:user] = uri.user if uri.user
          opts[:pass] = uri.password if uri.password
         end
        
        if @options[:daemonize]
          daemonize(@options[:log_file])
        end

        if !ENV['WAKAME_AGENT_ID'].nil? && ENV['WAKAME_AGENT_ID'].nil? != ''
          opts[:agent_id] = ENV['WAKAME_AGENT_ID']
        end

        Initializer.run(:process_agent)

        EM.epoll if Wakame.config.eventmachine_use_epoll
        EM.run {
          Wakame::Agent.start(opts)
        }
      end

    end
  end
end
