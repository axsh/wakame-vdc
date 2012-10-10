# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Account < Dcmgr::Endpoints::ResponseGenerator
    def initialize(account)
      raise ArgumentError if !account.is_a?(Dcmgr::Models::Account)
      @account = account
    end

    def generate()
      @account.instance_exec {
        {:id=>canonical_uuid,
          :created_at => created_at,
          :updated_at => updated_at,
        }
      }
    end
  end

  class AccountUsage < Dcmgr::Endpoints::ResponseGenerator
    def initialize(account, usage_hash)
      raise ArgumentError if !account.is_a?(Dcmgr::Models::Account)
      raise ArgumentError if !usage_hash.is_a?(Hash)
      @account = account
      @usage_hash = usage_hash
    end

    def generate()
      @usage_hash
    end
  end

  class AccountCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        Account.new(i).generate
      }
    end
  end
end
