# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::Errors
  class APIError < RuntimeError
    attr_reader :response

    def initialize(response, message = nil)
      @response = response
      @message  = message
    end
  end

  # 4xx Client Error
  class ClientError < APIError; end

  # 400 Bad Request
  class BadRequest < ClientError; end

  # 401 Unauthorized
  class UnauthorizedAccess < ClientError; end

  # 403 Forbidden
  class ForbiddenAccess < ClientError; end

  # 404 Not Found
  class ResourceNotFound < ClientError; end

  # 409 Conflict
  class ResourceConflict < ClientError; end

  # 410 Gone
  class ResourceGone < ClientError; end

  # 5xx Server Error
  class ServerError < APIError; end
end
