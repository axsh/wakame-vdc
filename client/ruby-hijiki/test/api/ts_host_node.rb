# -*- coding: utf-8 -*-

class TestHostNode <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1112 then Hijiki::DcmgrResource::V1112::HostNode
    when :v1203 then Hijiki::DcmgrResource::V1203::HostNode
    end
  end

  include TestBaseMethods

  def test_host_node
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        host_node = api_class(api_ver).find(:first).results.first

        if api_ver == :v1112
          assert_equal(nil, host_node.node_id)
        else
          assert_not_equal(nil, host_node.node_id)
        end
      }
    }
  end

end
