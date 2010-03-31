require 'active_support'

module Dcmgr
  def self.route(rest_class, method, block, params2)
    proc do |*request_ids|
      logger.debug "URL: #{method} #{request.url} #{request_ids}"
      content_type 'application/json', :charset => 'utf-8'

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
          logger.debug "response(json): #{ret}"
        }

      rescue StandardError => e
        logger.info "err! #{e}\n" +
          "  " + e.backtrace.join("\n  ")
        code = Dcmgr.errorcode(e)
        body = {"errors"=>[e.to_s]}.to_json
        logger.info "exception #{e.class}, code: #{code}, body: #{body}"
        throw :halt, [code, body]

      rescue e
        logger.info "err! #{e}\n" +
          "  " + e.backtrace.join("\n  ")
        throw :halt, [500, e.to_s]
      end
    end
  end

  def self.errorcode(e)
    require 'dcmgr/evaluator'
    
    case e
    when Models::InvalidUUIDError, Models::DuplicateUUIDError
      400 # ActiveResource::BadRequest
    when RoleError
      403 # ActiveResource::ForbiddenAccess
    when PhysicalHostScheduler::NoPhysicalHostError
      404 # ActiveResource::ResourceNotFound
    when RestModels::InvalidParameterError, Sequel::ValidationFailed
      422 # ActiveResource::ResourceInvalid
    else
      500 # ActiveResource::ServerError
    end
  end
end
