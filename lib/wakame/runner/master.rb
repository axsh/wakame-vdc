require 'optparse'
require 'amqp'

module Wakame
  module Runner
    class Master
      include Wakame::Daemonize

      def initialize(argv)
        @argv = argv

        @options = {
          :amqp_server => URI.parse('amqp://guest@localhost/'),
          :log_file => '/var/log/wakame-master.log',
          :pid_file => '/var/run/wakame/wakame-master.pid',
          :daemonize => true
        }

        parser.parse! @argv
      end


      def parser
        @parser ||= OptionParser.new do |opts|
          opts.banner = "Usage: master [options]"

          opts.separator ""
          opts.separator "Master options:"
          opts.on( "-p", "--pid PIDFILE", "pid file path" ) {|str| @options[:pid_file] = str }
          opts.on( "-u", "--uid UID", "user id for the running process" ) {|str| @options[:uid] = str }
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
          Signal.trap(i) { Wakame::Master.stop{ remove_pidfile } }
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

        change_privilege(@options[:uid]) if @options[:uid]

        Initializer.run(:process_master)

        EM.epoll if Wakame.config.eventmachine_use_epoll
        EM.run {
          Wakame::Master.start(opts)

          EM.add_periodic_timer(5) {
            next
            buf = ''
            buf << "<--- RUNNING THREADS --->\n"
            ThreadGroup::Default.list.each { |i|
              buf << "#{i.inspect} #{i[:name].to_s}\n"
            }
            buf << ">--- RUNNING THREADS ---<\n"
            puts buf
          }
        }
      end

    end
  end
end
