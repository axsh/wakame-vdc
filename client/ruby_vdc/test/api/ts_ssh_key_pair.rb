# -*- coding: utf-8 -*-

require 'test/unit'

class TestSshKeyPair <  Test::Unit::TestCase
  def test_ssh_key_pair_1112
    assert_nothing_raised() {
      ssh_key_pair = DcmgrResource::V1112::SshKeyPair.find(:first).results.first

      # puts "ssh_key_pair_1112.inspect: #{ssh_key_pair.inspect}"
    }
  end

  def test_ssh_key_pair_1203
    assert_nothing_raised() {
      ssh_key_pair = DcmgrResource::V1203::SshKeyPair.find(:first).results.first

      # puts "ssh_key_pair_1203.inspect: #{ssh_key_pair.inspect}"
    }
  end

end
