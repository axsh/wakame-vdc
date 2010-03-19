require 'active_support'

module Dcmgr
  def self.route(rest_class, method, block, params2)
    proc do |*request_ids|
      logger.debug "URL: #{method} #{request.url} #{request_ids}"

      begin
        user = protected! if rest_class.protect?
        if user and user.respond_to? :uuid
          logger.debug "authorized user: #{user.uuid}"
        else
          logger.debug "not authorize"
        end

        obj = rest_class.new(:user=>user,
                             :request=>request,
                             :fsuser=>@fsuser,
                             :request_ids=>request_ids,
                             :action_name=>params2[:action_name])
        obj.response(block).tap{|ret|
          logger.debug "response(json): %s" + ret
        }

      rescue StandardError => e
        logger.info "err! #{e}\n" +
          "  " + e.backtrace.join("\n  ")
        throw :halt, [400, e.to_s]
      end
    end
  end
end
