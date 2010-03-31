
require 'uri'
require 'thin'
require 'thread'
require 'json'

module Wakame
  module MasterManagers
    class CommandQueue
      include MasterManager

      def initialize()
        @queue = Queue.new
        @result_queue = Queue.new
        @statistics = {
          :total_command_count => 0
        }
      end

      def init
        @command_thread = Thread.new {
          Wakame.log.info("#{self.class}: Started command thread: #{Thread.current}")
          while cmd = @queue.deq
            begin
              unless cmd.kind_of?(Wakame::Command)
                Wakame.log.warn("#{self.class}: Incompatible type of object has been sent to ProcessCommand thread. #{cmd.class}")
                next
              end

              res = nil
              Wakame.log.debug("#{self.class}: Being processed the command: #{cmd.class}")
              res = cmd.run
              res
            rescue => e
              Wakame.log.error(e)
              res = e
            ensure
              @result_queue.enq(res)
            end
          end
        }

        cmdsv_uri = URI.parse(Wakame.config.http_command_server_uri)

        @thin_server = Thin::Server.new(cmdsv_uri.host, cmdsv_uri.port, Adapter.new(self))
        @thin_server.threaded = true
        @thin_server.start
      end

      def terminate
        @thin_server.stop
        @command_thread.kill
      end

      def send_cmd(cmd)
        begin
          @queue.enq(cmd)

          ED.fire_event(Event::CommandReceived.new(cmd))

          return @result_queue.deq()
        rescue => e
          Wakame.log.error("#{self.class}:")
          Wakame.log.error(e)
        end
      end


      class Adapter
        
        def initialize(command_queue)
          @command_queue = command_queue
        end
        
        def call(env)
          req = Rack::Request.new(env)
          action_name, param_body = 
            case req.request_method
            when 'GET'
              query = req.query_string()
              if Wakame.config.enable_authentication == "true"
                begin
                  authentication(req.params, query)
                rescue => e
                  return make_res(403, 'auth failed')
                end
              end

              [req.params['action'], req.params]
            when 'POST'
              return make_res(415, 'Unsupported media type') if req.content_type !~ %r{text/javascript}
              
              case req.path_info
              when %r{^/instance/(\w+)}
                action_name = $1
              else
                return make_res(404, "no such path")
              end
              
              [action_name, JSON.load(req.body)]
            else
              return make_res(405, "Unsupported method type")
            end
          
          begin
            cmd = eval("Command::#{action_name.split('_').collect{|c| c.capitalize}.join}").new
            cmd.options = param_body
          rescue => e
            return make_res(404, 'no such path')
          end
          
          cmd_res = @command_queue.send_cmd(cmd)
           
          return cmd_res.is_a?(Exception) ? make_res(500, cmd_res.message) : make_res(200, 'OK')
        end

        private
        def authentication(path, query)
          key = Wakame.config.private_key
          req = query.split(/\&signature\=/)
          hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, key, req[0])
          hmac = Base64.encode64(hash).gsub(/\+/, "").gsub(/\n/, "").to_s
          if hmac != path["signature"]
            raise "Authentication failed"
          end
        end

        def make_res(status, msg)
          [status, {'Content-Type' => 'text/javascript+json'}, [[{:status=>status, :message=>msg.to_s}].to_json]]
        end
      end

    end
  end
end
