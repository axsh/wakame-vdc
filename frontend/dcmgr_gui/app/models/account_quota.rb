# -*- coding: utf-8 -*-

Sequel.inflections do |i|
  i.uncountable "account_quota"
end

class AccountQuota < BaseNew
  with_timestamps

  many_to_one :account


end
