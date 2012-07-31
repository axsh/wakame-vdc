# -*- coding: utf-8 -*-

module Dcmgr

  module Endpoints
    
    autoload :Errors, 'dcmgr/endpoints/errors'
    autoload :Helpers, 'dcmgr/endpoints/helpers'
    autoload :ResponseGenerator, 'dcmgr/endpoints/response_generator'

    module V1203
      module Responses
        autoload :Network, 'dcmgr/endpoints/12.03/responses/network'
      end

      autoload :CoreAPI, 'dcmgr/endpoints/12.03/core_api'
    end

  end
end
