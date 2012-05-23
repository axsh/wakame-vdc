# -*- coding: utf-8 -*-

require 'test/unit'

class TestImage <  Test::Unit::TestCase
  def test_image_1112
    assert_nothing_raised() {
      image = DcmgrResource::V1112::Image.find(:first).results.first

      uri = image.source.uri
      features = image.features
    }
  end

  def test_image_1203
    assert_nothing_raised() {
      image = DcmgrResource::V1203::Image.find(:first).results.first

      uri = image.source.uri
      features = image.features
    }
  end

end
