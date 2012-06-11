# -*- coding: utf-8 -*-

class TestNetwork <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1203 then Hijiki::DcmgrResource::V1203::Network
    end
  end

  include TestBaseMethods

  def test_network
    [:v1203].each { |api_ver|
      assert_nothing_raised() {
        object = api_class(api_ver).find(:first).results.first

        assert(object.uuid =~ /^nw-[0-9a-z]*$/)
        assert_not_nil(object.account_id)
      }
    }
  end

end
