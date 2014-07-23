# -*- coding: utf-8 -*-

class TestHostNode <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1203 then Hijiki::DcmgrResource::V1203::HostNode
    end
  end

  include TestBaseMethods

  def test_host_node
    [:v1203].each { |api_ver|
      assert_nothing_raised() {
        host_node = api_class(api_ver).find(:first).results.first
      }
    }
  end

end
