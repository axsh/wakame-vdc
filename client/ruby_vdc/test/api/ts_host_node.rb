# -*- coding: utf-8 -*-

require 'test/unit'

class TestHostNode <  Test::Unit::TestCase
  def test_host_node_1112
    assert_nothing_raised() {
      host_node = DcmgrResource::V1112::HostNode.find(:first).results.first

      # puts "host_node_1112.inspect: #{host_node.inspect}"

      assert_equal(nil, host_node.node_id)
    }
  end

  def test_host_node_1203
    assert_nothing_raised() {
      host_node = DcmgrResource::V1203::HostNode.find(:first).results.first

      # puts "host_node_1203.inspect: #{host_node.inspect}"

      assert_not_equal(nil, host_node.node_id)
    }
  end

end
