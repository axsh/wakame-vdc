# -*- coding: utf-8 -*-

module Dcmgr::Models
  class RequestLog < BaseNew

    inheritable_schema do
      String :request_id, :null=>false, :size=>40, :unique=>true
      Fixnum :frontend_system_id, :null=>false
      Fixnum :account_id, :null=>false
      String :requester_symbol, :null=>false, :size=>100
      # HTTP Response Code
      Fixnum :response_status, :null=>false
      String :response_msg
      String :api_path, :null=>false
      String :params, :null=>false
      Time :requested_at
      Time :responsed_at
    end

    def after_initialize
      self[:request_id] #
    end
    
  end
end
