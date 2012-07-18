# -*- coding: utf-8 -*-

class TestVolume <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1203 then Hijiki::DcmgrResource::V1203::Volume
    end
  end

  def test_volume
    [:v1203].each { |api_ver|
      assert_nothing_raised() {
        object = api_class(api_ver).find(:first).results.first
      }
    }
  end

end
