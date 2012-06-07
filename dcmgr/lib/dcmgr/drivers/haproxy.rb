module Dcmgr
  module Drivers
    class Haproxy

      include Dcmgr::Logger
      include Dcmgr::Helpers::TemplateHelper

      template_base_dir "haproxy"
      
      attr_reader :listen
      
      def initialize(mode)
        @listen = {}
        @listen[:servers] = {} 
        set_mode(mode)
        set_balance('leastconn')
        set_appsession({})
        set_name('balancer')
        set_bind('*', 80)
        @listen
      end
     
      def bind(&blk)
        begin
          raise "Undefined server" if servers.length == 0 

          template_file_path = "haproxy.cfg"
          render_template(template_file_path, output_file_path) do
            binding
          end
          logger.info("Create config file: #{output_file_path}")
          blk.call
          logger.info("Update #{template_file_path}")
        rescue ::Exception => e
          logger.error("Faild to bind HAProxy: #{e.message}")
        ensure
          remove_temporary
          logger.info("Delete config file: #{output_file_path}")
        end
      end

      def remove_temporary
        ::FileUtils.rm(output_file_path)  
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
      
      def set_cookie_name(name)
        @listen[:appsession][:cookie] = name
      end
      
      def set_mode(mode)

        if !['tcp', 'http', 'health'].include? mode
          raise 'Undefined mode.'
        end

        @listen[:mode] = mode
      end
      
      def set_balance(name, param = nil)

        if !['roundrobin', 'static-rr', 'leastconn', 'source', 'uri',
         'url_param','hdr', 'rdp-cookie'].include? name
          raise 'Undefined balance algorithm.'
        end

        balance = name
        balance += " (param)" unless param.nil?

        @listen[:balance] = balance
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

      def tmp_path
        '/var/tmp'
      end

      def tmp_file
        "haproxy-#{self.object_id}.cfg"
      end
 
      def output_file_path
        File.join(tmp_path, tmp_file)
      end
      
    end
  end
end
