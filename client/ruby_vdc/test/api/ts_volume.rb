# -*- coding: utf-8 -*-

require 'test/unit'

class TestVolume <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1112 then DcmgrResource::V1112::Volume
    when :v1203 then DcmgrResource::V1203::Volume
    end
  end

  include TestBaseMethods

  def test_volume
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        volume = api_class(api_ver).find(:first).results.first

        if api_ver == :v1112
          assert_raise(NoMethodError) { volume.account_id }
          assert_equal(String, volume.instance_id.class)
        else
          assert_not_nil(volume.account_id)
          assert_equal(Fixnum, volume.instance_id.class)
        end
      }
    }
  end

end
