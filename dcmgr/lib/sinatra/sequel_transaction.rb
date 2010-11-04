# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sequel'

module Sinatra
  # wrap routed request with sequel transaction block.
  module SequelTransaction
    module Helpers
      private
      def route_eval(&block)
        db = Sequel::DATABASES.first

        db.transaction do
          ret = instance_eval(&block)
        end
        throw :halt, ret
      end
    end

    def self.registered(app)
      app.helpers SequelTransaction::Helpers
    end
  end

end
