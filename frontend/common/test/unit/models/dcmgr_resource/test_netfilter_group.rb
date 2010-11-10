require 'rubygems'
require 'test/unit'
require 'active_resource'

require File.expand_path('../../../../lib/models/dcmgr_resource/base')
require File.expand_path('../../../../lib/models/dcmgr_resource/netfilter_group')

module Frontend
  class TestNetfilterGroup < Test::Unit::TestCase
    def setup
      @netfilter_group = Frontend::Models::DcmgrResource::NetfilterGroup
      @netfilter_group.set_debug
      @group_name = 'test'
      @uuid = 'ng-78oabyca'
    end

    def teardown
    end
    
    def test_create
      params = {
        :name => @group_name,
        :description => 'test',
        :rule => "\ntcp:22,22,ip4:0.0.0.0\ntcp:80,80,ip4:0.0.0.0\n#tcp:443,443,ip4:0.0.0.0\nudp:53,53,ip4:0.0.0.0\nicmp:-1,-1,ip4:0.0.0.0\n"
      }
      p @netfilter_group.create(params)
    end
    
    def test_list
      params = {
        :start => 0,
        :limit => 2
      }

      p @netfilter_group.list(params)[0]
    end
    
    def test_show
      p @netfilter_group.show(@uuid)
    end
    
    def test_update
      params = {
        :name => @group_name,
        :description => 'test',
        :rule => "\ntcp:22,22,ip4:0.0.0.0\ntcp:80,80,ip4:0.0.0.0\n#tcp:443,443,ip4:0.0.0.0\nudp:53,53,ip4:0.0.0.0\nicmp:-1,-1,ip4:0.0.0.0\n"
      }
      p @netfilter_group.update(@uuid,params)
    end
    
    def test_destroy
      p @netfilter_group.destroy(@uuid)
    end
    
    def test_all_group_list
      result = @netfilter_group.list
      data = result[0]
      assert_equal(data.results.size,data.owner_total)
    end
  end
end