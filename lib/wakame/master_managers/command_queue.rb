
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
          begin
            unless req.get?().to_s == "true"
              raise "No Support Response"
            end
            query = req.query_string()
            params = req.params()
            if Wakame.config.enable_authentication == "true"
              auth = authentication(params, query)
            end
            cname = params["action"].split("_")
            begin
              cmd = eval("Command::#{(cname.collect{|c| c.capitalize}).join}").new 
              cmd.options = params
              command = @command_queue.send_cmd(cmd)

              if command.is_a?(Exception)
                status = 500
                body = json_encode(status, command.message)
              else
                status = 200
                body = json_encode(status, "OK", command)
              end
            rescue => e
              status = 404
              body = json_encode(status, e)
            end
          rescue => e
            status = 403
            body = json_encode(status, e)
            Wakame.log.error(e)
          end
          [ status, {'Content-Type' => 'text/javascript+json'}, body]
        end

        def authentication(path, query)
          key = Wakame.config.private_key
          req = query.split(/\&signature\=/)
          hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, key, req[0])
          hmac = Base64.encode64(hash).gsub(/\+/, "").gsub(/\n/, "").to_s
          if hmac != path["signature"]
            raise "Authentication failed"
          end
        end

        def json_encode(status, message, data=nil)
          if status == 200 && data.is_a?(Hash)
            body = [{:status=>status, :message=>message}, {:data=>data}].to_json
          else
            body = [{:status=>status, :message=>message}].to_json
          end
          body
        end
      end

    end
  end
end
