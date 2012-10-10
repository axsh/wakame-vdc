
require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled? :netfilter_group_api_apec
  cfg = get_config[:netfilter_group_api_apec]

  describe "/api/security_groups" do
    @@res = []
    cfg[:groups_to_create].each_with_index { |group,i|
      it "Should create group #{group[:name]}" do
        @@res[i] = APITest.create('/security_groups.json', group)
        @@res[i].success?.should be_true
      end
    }

    cfg[:groups_to_create].each_with_index { |group,i|
      it "Should update data of group #{group[:name]}" do
        APITest.update("/security_groups/#{@@res[i]["uuid"]}", {:description=>"#{group[:description]}(new)", :rule => cfg[:update_rule]}).success?.should be_true
      end
    }

    cfg[:groups_to_create].each_with_index { |group,i|
      it "Should delete group #{group[:name]}" do
        APITest.delete("/security_groups/#{@@res[i]["uuid"]}").success?.should be_true
      end
    }
  end
end
