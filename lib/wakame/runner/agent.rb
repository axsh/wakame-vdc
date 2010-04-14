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
          :log_file => '/var/log/wakame-agent.log',
          :pid_file => '/var/run/wakame/wakame-agent.pid',
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

        unless @options[:amqp_server].nil?
          uri = @options[:amqp_server]
          default = ::AMQP.settings
          opts = {:host => uri.host, 
            :port => uri.port || default[:port],
            :vhost => uri.vhost || default[:vhost],
            :user=>uri.user || default[:user],
            :pass=>uri.password ||default[:pass]
          }
        else
          opts = nil
        end
        
        if @options[:daemonize]
          daemonize(@options[:log_file])
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
