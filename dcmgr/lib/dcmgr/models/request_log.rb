# -*- coding: utf-8 -*-

module Dcmgr::Models
  class RequestLog < BaseNew

    inheritable_schema do
      String :request_id, :null=>false, :size=>40, :unique=>true
      String :frontend_system_id, :null=>false, :size=>40
      String :account_id, :null=>false, :size=>40
      String :requester_token, :null=>true, :size=>100
      # HTTP Request Content
      String :request_method, :null=>false, :size=>10
      String :api_path, :null=>false
      Text   :params, :null=>false
      # HTTP Response Content
      Fixnum :response_status, :null=>false
      Text   :response_msg, :null=>true
      Time :requested_at, :null=>false
      Fixnum :requested_at_usec, :null=>false, :unsigned=>true
      Time :responded_at, :null=>false
      Fixnum :responded_at_usec, :null=>false, :unsigned=>true
    end

    plugin :serialization
    serialize_attributes :yaml, :params

    def after_initialize
      super
      self[:request_id] ||= Isono::Util.gen_id
      t = Time.now
      self[:requested_at] = t
      self[:requested_at_usec] = t.usec
    end

    def before_create
      super
      t = Time.now
      self[:responded_at] = t
      self[:responded_at_usec] = t.usec
    end

  end
end
