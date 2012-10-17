
require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled? :ssh_key_pairs_api_spec
  cfg = get_config[:ssh_key_pairs_api_spec]

  describe "/api/ssh_key_pair" do

    it "should show key pair list" do
      res = APITest.get("/ssh_key_pairs")
      res.success?.should be_true
    end

    it "should create a new key: #{cfg[:name]}" do
      res = APITest.create('/ssh_key_pairs', cfg.merge(:description=>'description1'))
      res.success?.should be_true
      @@created_key = res
    end

    it "should show the new key: #{cfg[:name]}" do
      APITest.get("/ssh_key_pairs/#{@@created_key["id"]}").success?.should be_true
    end

    it_should_behave_like "show_api", "/ssh_key_pairs", nil

    it "should set the description field: #{cfg[:name]}" do
      # make the field empty.
      APITest.update("/ssh_key_pairs/#{@@created_key["id"]}", :description=>"").success?.should be_true
      # set new message again.
      APITest.update("/ssh_key_pairs/#{@@created_key["id"]}", :description=>"description2").success?.should be_true
    end

    it "should delete the new key: #{cfg[:name]}" do
      APITest.delete("/ssh_key_pairs/#{@@created_key["id"]}").success?.should be_true
    end

  end
end
