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
        raise "Unknown mode. #{mode}" unless ['http', 'tcp'].include? mode

        @listen = {}
        @listen[:servers] = {}
        @listen[:bind] = []
        @listen[:acl] = []
        @listen[:reqadd] = []
        set_balance_algorithm('leastconn')
        set_name('balancer')
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
        @listen[:bind] << "#{address}:#{port}"
      end

      def set_name(name)
        @listen[:name] = name
      end

      def set_acl(name, criterion, value)
        @listen[:acl] << "#{name} #{criterion} #{value}"
      end

      def set_x_forwarded_proto(protocol, ports)
        case protocol
          when 'https'
            set_acl('is-https', 'dst_port', ports)
            @listen[:reqadd] << 'X-Forwarded-Proto:\ https if is-https'
          when 'http'
            ports.each do |port|
              set_acl('is-http', 'dst_port', port)
            end
            @listen[:reqadd] << 'X-Forwarded-Proto:\ http if is-http'
        end
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
