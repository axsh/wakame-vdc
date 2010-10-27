require 'rubygems'
require 'test/unit'
require 'active_resource'
require 'pp'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/image')

module Frontend
  class TestVolume < Test::Unit::TestCase
    def setup
      @image = Frontend::Models::DcmgrResource::Image
      @image.set_debug
    end

    def teardown
    end

    def test_list
      params = {
        :start => 0,
        :limit => 10
      }
      pp @image.list(params)
    end
    
    def test_show
      image_id = 'wmi-640cbf3r'
      p @image.show(image_id)
    end
  end
end