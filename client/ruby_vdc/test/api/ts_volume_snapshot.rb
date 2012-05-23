# -*- coding: utf-8 -*-

require 'test/unit'

class TestVolumeSnapshot <  Test::Unit::TestCase
  def test_volume_1112
    assert_nothing_raised() {
      volume_snapshot = DcmgrResource::V1112::VolumeSnapshot.find(:first).results.first

      # puts "volume_snapshot_1112.inspect: #{volume_snapshot.inspect}"
    }
  end

  def test_volume_1203
    assert_nothing_raised() {
      volume_snapshot = DcmgrResource::V1203::VolumeSnapshot.find(:first).results.first

      # puts "volume_snapshot_1203.inspect: #{volume_snapshot.inspect}"
    }
  end

end
