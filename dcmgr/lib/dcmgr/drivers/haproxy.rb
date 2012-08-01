module Dcmgr
  module Drivers
    class Haproxy

      include Dcmgr::Logger
      include Dcmgr::Helpers::TemplateHelper

      attr_reader :listen

      @template_base_dir = "haproxy"

      def self.mode(protocol)
        case protocol
          when 'http','https'
            'http'
          when 'tcp', 'ssl'
            'tcp'
        end
      end

      def initialize(mode)
        raise "Unknown mode." unless ['http', 'tcp'].include? mode

        @listen = {}
        @listen[:servers] = {}
        set_balance_algorithm('leastconn')
        set_name('balancer')
        set_bind('*', 80)
        @mode = mode

        @listen
      end

      def template_file_path
        case @mode
          when 'http'
            'haproxy_http.cfg'
          when 'tcp'
            'haproxy_tcp.cfg'
        end
      end

      def add_server(address, port, options = {})

         if @listen[:servers].has_key? address
           name = @listen[:servers][address][:name]
           cookie = @listen[:servers][address][:cookie]
         else
           name = next_server_name
           cookie = next_cookie_name
         end

         @listen[:servers][address] = {
           :name => name,
           :address => address,
           :port => port,
           :cookie => cookie,
           :maxconn => 1000
         }
         @listen[:servers][address].merge!(options)
         servers
      end

      def remove_server(address)
        @listen[:servers].delete(address)
        servers
      end

      def set_cookie_name(name)
        if @mode == 'http' && !name.empty?
          set_appsession({:cookie => name })
        end
      end

      def set_balance_algorithm(algorithm, param = nil)

        if !['roundrobin', 'static-rr', 'leastconn', 'source', 'uri',
         'url_param','hdr', 'rdp-cookie'].include? algorithm
          raise 'Undefined balance_algorithm algorithm.'
        end

        @listen[:balance_algorithm] = algorithm
      end

      def set_appsession(appsession)
        @listen[:appsession] = {
          :cookie => 'SERVERID',
          :length => '4096',
          :holdtime => '24h'
        }
        @listen[:appsession].merge!(appsession)
      end

      def set_bind(address, port)
        @listen[:bind] = "#{address}:#{port}"
      end

      def set_name(name)
        @listen[:name] = name
      end

      private

      def next_server_name
        "srv-#{total_server+1}"
      end

      def next_cookie_name
        "cookie-#{total_server+1}"
      end

      def total_server
        @listen[:servers].length.to_i
      end

      def servers
        @listen[:servers]
      end
    end
  end
end
