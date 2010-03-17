require 'active_support'

module Dcmgr
  def self.route(rest_c, method, block, params)
    proc do |*args|
      logger.debug "URL: #{method} #{request.url} #{args}"

      begin
        user = protected! if rest_c.protect?
        if user and user.respond_to? :uuid
          logger.debug "authorized user: #{user.uuid}"
        else
          logger.debug "not authorize"
        end

        obj = rest_c.new(:user=>user, :request=>request,
                         :fsuser=>@fsuser,
                         :target_uuid=>args)
        obj.uuid = args[0] if args.length > 0
        ret = obj.get_response(block)

        logger.debug "response: " + ret.inspect
        json_ret = ret.to_json
        logger.debug "response(json): " + json_ret
        json_ret

      rescue StandardError => e
        logger.info "err! #{e}"
        logger.info "  " + e.backtrace.join("\n  ")
        throw :halt, [400, e.to_s]
      end
    end
  end
end
