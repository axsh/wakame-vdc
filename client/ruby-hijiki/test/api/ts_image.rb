# -*- coding: utf-8 -*-

class TestImage <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1203 then Hijiki::DcmgrResource::V1203::Image
    end
  end

  include TestBaseMethods

  def test_image
    [:v1203].each { |api_ver|
      assert_nothing_raised() {
        image = api_class(api_ver).find(:first).results.first

        assert_not_nil(image.features)
      }
    }
  end

end
