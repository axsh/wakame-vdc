
require File.expand_path('../spec_helper', __FILE__)

describe "/api/images" do
  include CliHelper

  before :all do
    init_env
    cd_dcmgr_dir
  end

  # volume_min_size
  it "should show image list" do
    res = APITest.get("/images")
    res.success?.should be_true
  end

  it "should describe machine image (wmi-lucid0)" do
    image_id = "wmi-lucid0"
    res = APITest.get("/images/#{image_id}")
    res["id"].should == image_id
    res.success?.should be_true
  end

  it "should delete machine image (wmi-lucid0) and then register with CLI." do
    image_id = "wmi-lucid0"
    res = APITest.get("/images/#{image_id}")

    # TODO: Image should be registerd via API.
    require 'yaml'
    vmimage_uri = YAML.load(res["source"])[:uri]
    vmimage_path = URI.parse(vmimage_uri).path
    cmd = "./bin/vdc-manage image add local #{vmimage_path} -m #{res["md5sum"]} -a #{res["account_id"]} -u #{res["id"]} -r #{res["arch"]} -d \"#{res["description"]}\" -s init"

    res = APITest.delete("/images/#{image_id}")
    res.success?.should be_true

    `#{cmd}`
    $?.exitstatus.should == 0
  end

  it "should delete machine image (wmi-lucid1) and then register with CLI." do
    image_id = "wmi-lucid1"
    res = APITest.get("/images/#{image_id}")

    # TODO: Image should be registerd via API.
    require 'yaml'
    snap_id = YAML.load(res["source"])[:snapshot_id]
    cmd = "./bin/vdc-manage image add volume #{snap_id} -m #{res["md5sum"]} -a #{res["account_id"]} -u #{res["id"]} -r #{res["arch"]} -d \"#{res["description"]}\" -s init"

    res = APITest.delete("/images/#{image_id}")
    res.success?.should be_true

    `#{cmd}`
    $?.exitstatus.should == 0
  end

end
