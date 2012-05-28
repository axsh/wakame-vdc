# -*- coding: utf-8 -*-

class TestSshKeyPair <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1112 then DcmgrResource::V1112::SshKeyPair
    when :v1203 then DcmgrResource::V1203::SshKeyPair
    end
  end

  include TestBaseMethods

  def test_ssh_key_pair
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        ssh_key_pair = api_class(api_ver).find(:first).results.first
      }
    }
  end

end
