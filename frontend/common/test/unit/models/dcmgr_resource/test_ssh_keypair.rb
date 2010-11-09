require 'rubygems'
require 'test/unit'
require 'active_resource'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/ssh_key_pair')

module Frontend
  class TestVolume < Test::Unit::TestCase
    def setup
      @ssh_key_pair = Frontend::Models::DcmgrResource::SshKeyPair
      @ssh_key_pair.set_debug
      @uuid = 'ssh-odayzfyx'
      @key_name = 'test11'
    end

    def teardown
    end
    
    def test_list
      params = {
        :start => 0,
        :limit => 10
      }
      p @ssh_key_pair.list(params)
    end
    
    def test_create
      #Save private key file.
      params = {
        :name => @key_name,
        :download_once => false
      }
      p @ssh_key_pair.create(params)      
    end
    
    def test_create_with_download_once
      #Do not save private key file.
      params = {
        :name => @key_name,
        :download_once => true
      }
      p @ssh_key_pair.create(params)
    end
    
    def test_show
      p @ssh_key_pair.show(@uuid)
    end
    
    def test_destroy
      p @ssh_key_pair.destroy(@uuid)
    end

  end
end