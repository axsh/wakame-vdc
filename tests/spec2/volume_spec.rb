
require File.expand_path('../spec_helper', __FILE__)

describe "/api/volumes" do
  include VolumeHelper

  it "should create 10 MB blank volume and delete" do
    volume_id = create_volume({:volume_size => 10})
    APITest.get("/volumes/#{volume_id}")["size"].to_i.should == 10
    delete_volume(volume_id)
  end

  it "should create volume from snapshot snap-lucid1 and delete" do
    snap = APITest.get("/volume_snapshots/snap-lucid1")
    snap.success?.should be_true
    volume_id = create_volume({:snapshot_id=> snap["id"]})
    APITest.get("/volumes/#{volume_id}")["size"].to_i.should == snap["size"].to_i
    delete_volume(volume_id)
  end

  # volume_min_size
  it "should create blank volume less than minimum size. (volume_min_size 10)" do
    res = APITest.create("/volumes", {:volume_size=> 9})
    res.success?.should_not be_true
  end

  it "should create minimum size blank volume (volume_min_size 10)" do
    volume_id = create_volume({:volume_size => 10})
    APITest.get("/volumes/#{volume_id}")["size"].to_i.should == 10
    delete_volume(volume_id)
  end

  # volume_max_size
  it "should create blank volume more than maximum size. (volume_max_size 3000)" do
    res = APITest.create("/volumes", {:volume_size=> 3001})
    res.success?.should_not be_true
  end

  it "should create maximum size blank volume (volume_max_size 3000)" do
    volume_id = create_volume({:volume_size => 3000})
    APITest.get("/volumes/#{volume_id}")["size"].to_i.should == 3000
    delete_volume(volume_id)
  end

  private
  def create_volume(values)
    raise "parameter should not be empty" if values.nil?
    res = APITest.create("/volumes", values)
    res.success?.should be_true
    volume_id = res["id"]
    retry_until_available(:volumes, volume_id)
    volume_id
  end
end
