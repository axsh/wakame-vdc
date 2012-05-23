# -*- coding: utf-8 -*-

require 'test/unit'

class TestAccount <  Test::Unit::TestCase
  def test_account_1112
    assert_nothing_raised() {
      # account = DcmgrResource::V1112::Account.find(:first).results.first

      # puts "account_1112.inspect: #{account.inspect}"
    }
  end

  def test_account_1203
    assert_nothing_raised() {
      # account = DcmgrResource::V1203::Account.find(:first).results.first

      # puts "account_1203.inspect: #{account.inspect}"
    }
  end

end
