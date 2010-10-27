require 'rubygems'
require 'test/unit'
require 'active_resource'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/volume_snapshot')

module Frontend
  class TestVolumeSnapshot < Test::Unit::TestCase
    def setup
      @snapshot = Frontend::Models::DcmgrResource::VolumeSnapshot
      @snapshot.set_debug
    end

    def teardown
    end
    
    def test_list
      params = {
        :start => 0,
        :limit => 10
      }
      p @snapshot.list(params)
    end

    def test_show
      snapshot_id = "snap-65ghi5gs"
      p @snapshot.show(snapshot_id)
    end
    
    def test_create
      params = {
        :volume_id => "vol-nmxe5cda"
      }
      p @snapshot.create(params)
    end
    
    def test_destroy
      snapshot_id = 'snap-w1gz080l'
      p @snapshot.destroy(snapshot_id)
    end
    
    def test_status
      account_id = 'a-00000000'
      p @snapshot.status(account_id)
    end
  end
end
