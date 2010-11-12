require 'rubygems'
require 'test/unit'
require 'active_resource'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/instance')

module Frontend
  class TestInstance < Test::Unit::TestCase
    def setup
      @instance = Frontend::Models::DcmgrResource::Instance
      @instance.set_debug
    end

    def teardown
    end

    def test_list
      params = {
        :start => 0,
        :limit => 10
      }
      require 'pp'
      pp @instance.list(params)
    end
    
    def test_show
      instance_id = 'i-sahh531g'
      p @instance.show(instance_id)
    end
    
    def test_launch_instance
      params = {
        :image_id => 'wmi-640cbf3r',
        :host_pool_id => 'hp-hb4f6f84'
      }
      p @instance.create(params)
    end
    
    def test_terminate
      instance_id = 'i-trjjhgq0'
      p @instance.destroy(instance_id)
    end
    
    def test_reboot
      instance_id = 'i-ej1vekxx'
      p @instance.reboot(instance_id)
    end
  end
end