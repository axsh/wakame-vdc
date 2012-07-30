# -*- coding: utf-8 -*-

module Dcmgr

  module Endpoints
    
    autoload :Errors, 'dcmgr/endpoints/errors'
    autoload :Helpers, 'dcmgr/endpoints/helpers'

    module V1203
      module Responses
      end

      autoload :CoreAPI, 'dcmgr/endpoints/12.03/core_api'
    end

  end
end
