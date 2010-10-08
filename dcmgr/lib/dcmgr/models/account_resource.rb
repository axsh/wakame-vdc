# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Base class for the model class which belongs to a specific account.
  class AccountResource < BaseNew

    inheritable_schema do
      String :account_id, :null=>false, :index=>true
    end

    many_to_one :account

  end
end
