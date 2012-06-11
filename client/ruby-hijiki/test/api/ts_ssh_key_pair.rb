# -*- coding: utf-8 -*-

class TestSshKeyPair <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1203 then Hijiki::DcmgrResource::V1203::SshKeyPair
    end
  end

  include TestBaseMethods

  def test_ssh_key_pair
    [:v1203].each { |api_ver|
      assert_nothing_raised() {
        ssh_key_pair = api_class(api_ver).find(:first).results.first
      }
    }
  end

end
