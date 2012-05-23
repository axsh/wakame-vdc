# -*- coding: utf-8 -*-

require 'test/unit'

class TestInstance <  Test::Unit::TestCase
  def test_instance_1112
    assert_nothing_raised() {
      instance = DcmgrResource::V1112::Instance.find(:first).results.first

      # puts "instance_1112.inspect: #{instance.inspect}"
    }
  end

  def test_instance_1203
    assert_nothing_raised() {
      instance = DcmgrResource::V1203::Instance.find(:first).results.first

      # puts "instance_1203.inspect: #{instance.inspect}"
    }
  end

end
