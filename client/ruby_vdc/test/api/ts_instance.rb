# -*- coding: utf-8 -*-

require 'test/unit'

class TestInstance <  Test::Unit::TestCase
  def api_class(version)
    case version
    when :v1112 then DcmgrResource::V1112::Instance
    when :v1203 then DcmgrResource::V1203::Instance
    end
  end

  include TestBaseMethods

  def test_instance
    [:v1112, :v1203].each { |api_ver|
      assert_nothing_raised() {
        instance = api_class(api_ver).find(:first).results.first

        # puts "instance_1112.inspect: #{instance.inspect}"
      }
    }
  end

end
