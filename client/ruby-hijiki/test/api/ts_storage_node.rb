# -*- coding: utf-8 -*-

class TestStorageNode <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1203 then Hijiki::DcmgrResource::V1203::StorageNode
    end
  end

  include TestBaseMethods

  def test_storage_node
    [:v1203].each { |api_ver|
      assert_nothing_raised() {
        storage_node = api_class(api_ver).find(:first).results.first
      }
    }
  end

  def test_list_1203
    [:v1203].each { |api_ver|
      assert_nothing_raised() {
        list = api_class(api_ver).list
      }
    }
  end

end
