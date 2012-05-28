# -*- coding: utf-8 -*-

require 'test/unit'

class TestVolumeSnapshot <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1112 then DcmgrResource::V1112::VolumeSnapshot
    when :v1203 then DcmgrResource::V1203::VolumeSnapshot
    end
  end

  include TestBaseMethods

  def test_volume_snapshot
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        volume_snapshot = api_class(api_ver).find(:first).results.first

        if api_ver == :v1112
          assert_raise(NoMethodError) { volume_snapshot.account_id }
          assert_raise(NoMethodError) { volume_snapshot.storage_node_id }
        else
          assert_not_nil(volume_snapshot.account_id)
          assert_equal(Fixnum, volume_snapshot.storage_node_id.class)
        end
      }
    }
  end

end
