require 'rubygems'
require 'test/unit'
require 'active_resource'
require 'pp'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/host_pool')

module Frontend
  class TestHostPool < Test::Unit::TestCase
    def setup
      @host_pool = Frontend::Models::DcmgrResource::HostPool
      @host_pool.set_debug
    end

    def teardown
    end

    def test_list
      params = {
        :start => 0,
        :limit => 10
      }
      pp @host_pool.list(params)
    end
    
    def test_show
      host_pool_id = 'hp-hb4f6f84'
      pp @host_pool.show(host_pool_id)
    end
  end
end