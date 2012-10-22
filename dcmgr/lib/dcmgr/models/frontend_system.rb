# -*- coding: utf-8 -*-

module Dcmgr::Models
  class FrontendSystem < BaseNew

    plugin :single_table_inheritance, :kind

    def authenticate
      raise NotImplementedError
    end

    class PassThru < FrontendSystem

      def authenticate(env)
      end
    end

    class HttpBasic < FrontendSystem

      def authenticate(env)
      end
    end

    class RemoteIP < FrontendSystem

      def authenticate(env)
        self.key == env['HTTP_REMOTE_ADDR']
      end
    end

  end
end
