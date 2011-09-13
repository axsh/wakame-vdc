
require File.expand_path('../spec_helper', __FILE__)

describe "/api/volumes" do
  include RetryHelper
  
  it "create 99MB blank volume and delete" do
    res = APITest.create("/volumes", {:volume_size=>99})
    res.success?.should be_true
    volume_id = res["id"]
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "available"
    end
    APITest.get("/volumes/#{volume_id}")["size"].to_i.should == 99
    APITest.delete("/volumes/#{volume_id}").success?.should be_true
  end

  it "create volume from snapshot snap-lucid1 and delete" do
    res = APITest.create("/volumes", {:snapshot_id=>'snap-lucid1'})
    res.success?.should be_true
    volume_id = res["id"]
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "available"
    end
    APITest.delete("/volumes/#{volume_id}").success?.should be_true
  end
  
end
