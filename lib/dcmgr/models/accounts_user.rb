require 'sequel'

module Dcmgr
  module Models
    class AccountsUser < Sequel::Model
      many_to_one :account
      many_to_one :user, :left_primary_key=>:user_id
    end
  end
end
