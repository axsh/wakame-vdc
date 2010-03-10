require 'active_support'

module Dcmgr
  def self.route(rest_c, method, block)
    proc do |*args|
      logger.debug "URL: #{method} #{request.url} #{args}"

      begin
        protected! if rest_c.protect?
      
        user = protected!
        if user and user.respond_to? :uuid
          logger.debug "authorized user: #{user.uuid}"
        else
          logger.debug "not authorize"
          #throw(:halt, [401, "Not authorized"])
        end

        obj = rest_c.new(user, request)
        obj.uuid = args[0] if args.length > 0

        ret = obj.instance_eval(&block)

        logger.debug "response(inspect): " + ret.inspect
        json_ret = obj.to_response(ret).to_json
        logger.debug "response(json): " + json_ret
        json_ret

      rescue StandardError => e
        logger.info "err! %s" % e.to_s
        logger.info "  " + e.backtrace.join("\n  ")
        throw :halt, [400, e.to_s]
      end
    end
  end
end
