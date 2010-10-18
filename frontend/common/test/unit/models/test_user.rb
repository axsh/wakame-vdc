require 'rubygems'
require 'test/unit'
require 'sequel/model'
require File.expand_path('../../../lib/schema')


#todo:Load config
@dcmgr_config = Frontend::Schema.config('test',File.join(File.expand_path('../../../'), 'config', 'database.yml'))
Frontend::Schema.connect "#{@dcmgr_config['adapter']}://#{@dcmgr_config['host']}/#{@dcmgr_config['database']}?user=#{@dcmgr_config['user']}&password=#{@dcmgr_config['password']}"

require File.expand_path('../../../lib/models/base_new')
require File.expand_path('../../../lib/models/user')
require File.expand_path('../../../lib/models/account')

module Frontend
  class TestUser < Test::Unit::TestCase
    def setup
      @obj = Frontend::Models::User.new
    end

    def teardown
    end

    def test_nil_login_id
      login_id = nil
      password = 'password'
      u = Models::User.authenticate(login_id,password)
      assert_nil(u)
    end
    
    def test_nil_password
      login_id = 'test'
      password = nil
      u = Models::User.authenticate(login_id,password)
      assert_nil(u)
    end

    def test_login_success
      login_id = 'test'
      password = 'password'
      u = Models::User.authenticate(login_id,password)
      assert_equal(u.login_id,login_id)
      assert_equal(u.password,password)
    end
    
    def test_login_fail
      login_id = 'test'
      password = 'aa'
      u = Models::User.authenticate(login_id,password)
      assert_equal(u,false)
    end
    
    def test_get_user
      login_id = 'test'
      password = 'password'
      u = Models::User.authenticate(login_id,password)
      r = Models::User.get_user(u.uuid)
      assert_equal(u.uuid,r.uuid)
    end
    
    def test_account_name_with_uuid
      uuid = 'u-wvd98v'
      accounts_name = Models::User.account_name_with_uuid(uuid)
      assert_equal(accounts_name,{'dcmgr' => 'a-9f14im'})
    end
    
    def test_primary_account_id
      user_uuid = 'u-wvd98v'
      account_uuid = Models::User.primary_account_id(user_uuid)
      assert_equal(account_uuid,'a-9f14im')
    end
  end
end