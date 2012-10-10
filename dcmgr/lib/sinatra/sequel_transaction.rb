# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sequel'

module Sinatra
  # Provide single DB transaction for single HTTP request and the
  # hooks that called after transaction. Hooks are also reset
  # at every requests.
  #
  # register Sinatra::SequelTransaction
  #
  # # Below POST block is wrapped with "BEGIN; COMMIT/ROLLBACK;" SQL
  # # queries.
  # post do
  #   Sequel::DATABASES.first['INSERT INTO xxxx .....']
  # end
  #
  # # The transaction is rolled back if an Exception is raised from
  # # the request block.
  # put do
  #   raise RuntimeError
  # end
  #
  # # Example of on_after_commit.
  # post do
  #   Sequel::DATABASES.first['INSERT INTO xxxx .....']
  #
  #   on_after_commit do
  #     puts "commited"
  #   end
  #   on_after_commit do
  #     puts "second hook"
  #   end
  # end
  module SequelTransaction
    module Helpers
      # TODO: abstract database connection. it means that do not use
      # Sequel::DATABASE.first where to get the connection.

      public
      # commit manually before return from the request block
      def commit_transaction
        STDERR.puts "Deprecated method. Use on_after_commit() instead."
      end

      def on_after_commit(&blk)
        Sequel::DATABASES.first.after_commit &blk
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
