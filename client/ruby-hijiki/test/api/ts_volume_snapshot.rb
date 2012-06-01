# -*- coding: utf-8 -*-

class TestVolumeSnapshot <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1112 then Hijiki::DcmgrResource::V1112::VolumeSnapshot
    when :v1203 then Hijiki::DcmgrResource::V1203::VolumeSnapshot
    end
  end

  include TestBaseMethods

  def test_volume_snapshot
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        object = api_class(api_ver).find(:first).results.first

        assert(object.origin_volume_id =~ /^vol-[0-9a-z]*$/)

        if api_ver == :v1112
          assert_raise(NoMethodError) { object.account_id }
          assert_raise(NoMethodError) { object.storage_node_id }

          assert_equal(nil, object.storage_node)
        else
          assert_not_nil(object.account_id)
          assert(object.storage_node_id =~ /^sn-[0-9a-z]*$/)

          assert_equal(Hijiki::DcmgrResource::V1203::StorageNode, object.storage_node.class)
        end
      }
    }
  end

end
