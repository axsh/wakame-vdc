# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sequel'

module Sinatra
  # wrap routed request with sequel transaction block.
  # note: this is NOT thread safe. please ensure not to be used in the
  # multi-threaded apps.
  module SequelTransaction
    module Helpers
      # TODO: abstract database connection. it means that do not use
      # Sequel::DATABASE.first where to get the connection.
      
      public
      # commit manually before return from the request block
      def commit_transaction
        db = Sequel::DATABASES.first
        db << db.__send__(:commit_transaction_sql)
      end
      
      private
      def route_eval(&block)
        
        db = Sequel::DATABASES.first
        begin
          db.transaction do
             super(&block)
          end
        rescue Sequel::DatabaseError, Sequel::DatabaseConnectionError => e
          db.disconnect
          raise e
        end
      end
    end

    def self.registered(app)
      app.helpers SequelTransaction::Helpers
    end
  end

end
