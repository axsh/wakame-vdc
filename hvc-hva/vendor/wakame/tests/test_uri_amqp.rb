
$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'

require 'test/unit'
require 'uri'
require 'ext/uri'

class TestUriAMQP < Test::Unit::TestCase
  def test_parse
    
    assert_equal('amqp://localhost/', URI.parse('amqp://localhost/').to_s)
    assert_equal('amqp://localhost:1122/', URI.parse('amqp://localhost:1122/').to_s)
    assert_equal('amqp://127.0.0.1/vvv', URI.parse('amqp://127.0.0.1/vvv').to_s)
    
    u=URI.parse('amqp://127.0.0.1/vvv')
    assert_equal('/vvv', u.vhost)
  end

  def test_build
    uri = URI::AMQP.build(:host=>'192.168.1.1', :path=>'/aaa')
    assert_equal('amqp://192.168.1.1/aaa', uri.to_s)
    uri.vhost = '/bbb'
    assert_equal('amqp://192.168.1.1/bbb', uri.to_s)

    uri = URI::AMQP.build(:host=>'192.168.1.1', :userinfo=>'a', :path=>nil)
    assert_equal('amqp://a@192.168.1.1/', uri.to_s)
  end
end
