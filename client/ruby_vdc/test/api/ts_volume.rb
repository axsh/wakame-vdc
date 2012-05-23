# -*- coding: utf-8 -*-

require 'test/unit'

class TestVolume <  Test::Unit::TestCase
  def test_volume_1112
    assert_nothing_raised() {
      volume = DcmgrResource::V1112::Volume.find(:first).results.first

      # puts "volume_1112.inspect: #{volume.inspect}"
    }
  end

  def test_volume_1203
    assert_nothing_raised() {
      volume = DcmgrResource::V1203::Volume.find(:first).results.first

      # puts "volume_1203.inspect: #{volume.inspect}"
    }
  end

end
