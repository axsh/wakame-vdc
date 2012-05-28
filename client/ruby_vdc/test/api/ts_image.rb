# -*- coding: utf-8 -*-

require 'test/unit'

class TestImage <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1112 then DcmgrResource::V1112::Image
    when :v1203 then DcmgrResource::V1203::Image
    end
  end

  include TestBaseMethods

  def test_image
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        image = api_class(api_ver).find(:first).results.first

        assert_not_nil(image.source.uri)
        assert_not_nil(image.features)
      }
    }
  end

end
