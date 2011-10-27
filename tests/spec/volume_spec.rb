
require File.expand_path('../spec_helper', __FILE__)

describe "/api/volumes" do
  include RetryHelper

  it "should create 99MB blank volume and delete" do
    res = APITest.create("/volumes", {:volume_size=>99})
    res.success?.should be_true
    volume_id = res["id"]
    retry_until_available(volume_id)
    APITest.get("/volumes/#{volume_id}")["size"].to_i.should == 99
    APITest.delete("/volumes/#{volume_id}").success?.should be_true
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
    end
  end

  it "should create volume from snapshot snap-lucid1 and delete" do
    snap = APITest.get("/volume_snapshots/snap-lucid1")
    snap.success?.should be_true
    res = APITest.create("/volumes", {:snapshot_id=>'snap-lucid1'})
    res.success?.should be_true
    volume_id = res["id"]
    retry_until_available(volume_id)
    APITest.get("/volumes/#{volume_id}")["size"].to_i.should == snap["size"].to_i
    APITest.delete("/volumes/#{volume_id}").success?.should be_true
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
    end
  end

  # volume_min_size
  it "should create blank volume less than minimum size. (volume_min_size 10)" do
    res = APITest.create("/volumes", {:volume_size=>9})
    res.success?.should_not be_true
  end

  it "should create minimum size blank volume (volume_min_size 10)" do
    res = APITest.create("/volumes", {:volume_size=>10})
    res.success?.should be_true
    volume_id = res["id"]
    retry_until_available(volume_id)
    APITest.get("/volumes/#{volume_id}")["size"].to_i.should == 10
    APITest.delete("/volumes/#{volume_id}").success?.should be_true
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
    end
  end

  # volume_max_size
  it "should create blank volume more than maximum size. (volume_max_size 3000)" do
    res = APITest.create("/volumes", {:volume_size=>3001})
    res.success?.should_not be_true
  end

  it "should create maximum size blank volume (volume_max_size 3000)" do
    res = APITest.create("/volumes", {:volume_size=>3000})
    res.success?.should be_true
    volume_id = res["id"]
    retry_until_available(volume_id)
    APITest.get("/volumes/#{volume_id}")["size"].to_i.should == 3000
    APITest.delete("/volumes/#{volume_id}").success?.should be_true
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
    end
  end

  private
  def retry_until_available(volume_id)
    retry_until do
      case APITest.get("/volumes/#{volume_id}")["state"]
      when 'available'
        true
      when 'deleted'
        raise "Volumes was deleted by the system due to failure."
      else
        false
      end
    end
  end

end
