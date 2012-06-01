# -*- coding: utf-8 -*-

class TestVolume <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1112 then Hijiki::DcmgrResource::V1112::Volume
    when :v1203 then Hijiki::DcmgrResource::V1203::Volume
    end
  end

  include TestBaseMethods

  def test_volume
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        object = api_class(api_ver).find(:first).results.first

        if api_ver == :v1112
          assert_raise(NoMethodError) { object.account_id }
          assert_equal(String, object.instance_id.class)
          assert(object.instance_id =~ /^i-[0-9]*/)
        else
          assert_not_nil(object.account_id)
          assert_equal(Fixnum, object.instance_id.class)
        end
      }
    }
  end

end
