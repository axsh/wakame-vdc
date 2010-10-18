require 'rubygems'
require 'test/unit'
require 'active_resource'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/volume_snapshot')

module Frontend
  class TestVolumeSnapshot < Test::Unit::TestCase
    def setup
      @snapshot = Frontend::Models::DcmgrResource::VolumeSnapshot
    end

    def teardown
    end
    
    def test_show
      account_id = 'a-00000000'
      p @snapshot.show(account_id)
    end
    
    def test_create
      p @snapshot.create
    end
    
    def test_destroy
      account_id = 'a-00000000'
      snapshot_id = 'snap-00000000'
      p @snapshot.destroy(account_id,snapshot_id)
    end
    
    def test_status
      account_id = 'a-00000000'
      p @snapshot.status(account_id)
    end
    
    def test_detail
      account_id = 'a-00000000'
      p @snapshot.detail(account_id)
    end
  end
end