# -*- coding: utf-8 -*-

require 'test/unit'

module TestBaseMethods
  def test_basic_1112
    ssh_key_pair = api_class(:v1112).find(:first,:params => {:start => 0,:limit => 1})

    assert_nothing_raised() { ssh_key_pair.total }
    assert_nothing_raised() { ssh_key_pair.owner_total }
  end

  def test_basic_1203
    ssh_key_pair = api_class(:v1203).find(:first,:params => {:start => 0,:limit => 1})

    assert_nothing_raised() { ssh_key_pair.total }
    assert_nothing_raised() { ssh_key_pair.owner_total }
  end
end
