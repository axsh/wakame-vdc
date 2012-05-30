# -*- coding: utf-8 -*-

require 'test/unit'

module TestBaseMethods
  def test_basic_1112
    [:v1112, :v1203].each { |api_ver|
      object = api_class(api_ver).find(:first,:params => {:start => 0,:limit => 1})

      assert_not_nil(object.total)
      assert_not_nil(object.owner_total)
    }
  end
end
