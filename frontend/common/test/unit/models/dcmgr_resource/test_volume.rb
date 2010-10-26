require 'rubygems'
require 'test/unit'
require 'active_resource'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/volume')

module Frontend
  class TestVolume < Test::Unit::TestCase
    def setup
      @volume = Frontend::Models::DcmgrResource::Volume
    end

    def teardown
    end

    def test_list
      params = {
        :start => 1,
        :limit => 10
      }
      p @volume.list(params).size
    end
    
    def test_create
      params = {
        :volume_size => 1024
      }
      p @volume.create(params)
    end
    
    def test_destroy
      account_id = 'a-00000000'
      volume_id = 'v-00000000'
      p @volume.destroy(account_id,volume_id)
    end
    
    def test_attach
      account_id = 'a-00000000'
      instance_id = 'i-00000000'
      p @volume.attach(account_id,instance_id)
    end
    
    def test_detach
      account_id = 'a-00000000'
      instance_id = 'i-00000000'
      p @volume.detach(account_id,instance_id)
    end
    
    def test_status
      account_id = 'a-00000000'
      p @volume.status(account_id)
    end
    
    def test_show
      volume_id = 'vol-24f1af01'
      p @volume.show(volume_id)
    end
  end
end