require 'rubygems'
require 'test/unit'
require 'active_resource'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/account')

module Frontend
    class TestAccount < Test::Unit::TestCase
      def setup
        @account = Frontend::Models::DcmgrResource::Account
      end

      def teardown
      end
  
      def test_show_account
        p @account.get('a-00000000')
      end
    end
end