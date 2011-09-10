
require File.expand_path('../spec_helper', __FILE__)

describe "/api/instances" do
  include RetryHelper
  
  it "runs new instance then terminate" do
    res = APITest.create("/instances", {:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec'})
    res.success?.should be_true
    instance_id = res["id"]
    retry_until do
      APITest.get("/instances/#{instance_id}")["state"] == "running"
    end
    APITest.delete("/instances/#{instance_id}").success?.should be_true
    
  end

  it "runs volume store instance" do
    res = APITest.create("/instances", {:image_id=>'wmi-lucid1', :instance_spec_id=>'is-demospec'})
    res.success?.should be_true
    instance_id = res["id"]
    retry_until do
      APITest.get("/instances/#{instance_id}")["state"] == "running"
    end
    APITest.delete("/instances/#{instance_id}").success?.should be_true
  end
end
