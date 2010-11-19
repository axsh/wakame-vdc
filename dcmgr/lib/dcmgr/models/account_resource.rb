# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Base class for the model class which belongs to a specific account.
  class AccountResource < BaseNew

    inheritable_schema do
      String :account_id, :null=>false, :index=>true
    end

    def account
      Account[self.account_id]
    end

  end
end
