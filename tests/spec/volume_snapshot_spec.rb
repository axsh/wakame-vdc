
require File.expand_path('../spec_helper', __FILE__)

describe "/api/volume_snapshots" do
  include RetryHelper

  it "should show destinations to upload volume snapshot." do
    res = APITest.get("/volume_snapshots/upload_destination")
    res.success?.should be_true

    dests = res.first["results"]
    dests[0]["destination_id"].should == "local"
    dests[1]["destination_id"].should == "s3"
    dests[2]["destination_id"].should == "iijgio"
  end

  it "should create snapshot from minimum blank volume to local and delete" do
    res = APITest.create("/volumes", {:volume_size=>10})
    res.success?.should be_true
    volume_id = res["id"]
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "available"
    end

    res = APITest.create("/volume_snapshots", {:volume_id=>volume_id, :destination=>"local"})
    snap_id = res["id"]
    res.success?.should be_true
    retry_until do
      APITest.get("/volume_snapshots/#{snap_id}")["state"] == "available"
    end

    APITest.delete("/volumes/#{volume_id}").success?.should be_true
    APITest.delete("/volume_snapshots/#{snap_id}").success?.should be_true
  end

end
