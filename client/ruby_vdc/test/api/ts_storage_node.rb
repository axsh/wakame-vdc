# -*- coding: utf-8 -*-

require 'test/unit'

class TestStorageNode <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1112 then DcmgrResource::V1112::StorageNode
    when :v1203 then DcmgrResource::V1203::StorageNode
    end
  end

  include TestBaseMethods

  def test_storage_node_1112
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        storage_node = api_class(api_ver).find(:first).results.first
        # assert_equal(nil, storage_node.node_id)
      }
    }
  end

  def test_list_1203
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        list = api_class(api_ver).list

        # puts "storage_node_1203.list.inspect: #{list.inspect}"
      }
    }
  end

end
