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

  def test_volume
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        volume_snapshot = api_class(api_ver).find(:first).results.first

        # puts "volume_snapshot_1112.inspect: #{volume_snapshot.inspect}"
      }
    }
  end

end
