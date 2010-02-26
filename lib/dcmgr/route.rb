
module Dcmgr
  def self.route(rest_c, method, block)
    proc do |*args|
      logger.debug "URL: #{method} #{request.url} #{args}"

      logger.debug rest_c.protect?.inspect
      
      protected! if rest_c.protect?
      
      begin parsed_request = json_request(request)
        user = authorized_user
        user_id = if user then user.id else 0 end
        user_uuid = if user.respond_to? :uuid
                    then user.uuid else "" end

        # log
        Log.create(:user_id=>user_id,
                   :account_id=>parsed_request[:account].to_i,
                   :target_uuid=>user_uuid,
                   :action=>'login')

        obj = rest_c.new(user, parsed_request)
        obj.uuid = args[0] if args.length > 0

        ret = obj.instance_eval(&block)

        logger.debug "response(inspect): " + ret.inspect
        json_ret = obj.to_response(ret).to_json
        logger.debug "response(json): " + json_ret + ", class: " + json_ret.class.to_s
        
        json_ret

      rescue StandardError => e
        logger.info "err! %s" % e.to_s
        logger.info "  " + e.backtrace.join("\n  ")
        throw :halt, [400, e.to_s]
      end
    end
  end
end
