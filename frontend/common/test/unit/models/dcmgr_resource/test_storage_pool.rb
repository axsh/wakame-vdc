require 'rubygems'
require 'test/unit'
require 'active_resource'
require 'pp'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/storage_pool')

module Frontend
  class TestStoragePool < Test::Unit::TestCase
    def setup
      @storage_pool = Frontend::Models::DcmgrResource::StoragePool
      @storage_pool.set_debug
    end

    def teardown
    end

    def test_list
      params = {
        :start => 0,
        :limit => 10
      }
      pp @storage_pool.list(params)
    end
    
    def test_show
      storage_pool_id = 'sp-1sx9jeks'
      pp @storage_pool.show(storage_pool_id)
    end
  end
end