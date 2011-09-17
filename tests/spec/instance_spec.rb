
require File.expand_path('../spec_helper', __FILE__)

describe "/api/instances" do
  include RetryHelper
  
  it "runs local store instance (wmi-lucid0,is-demospec) -> terminate" do
    res = APITest.create("/instances", {:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec'})
    res.success?.should be_true
    instance_id = res["id"]
    retry_until do
      APITest.get("/instances/#{instance_id}")["state"] == "running"
    end
    APITest.delete("/instances/#{instance_id}").success?.should be_true
    
  end

  it "runs volume store instance (wmi-lucid1,is-demospec) -> terminate" do
    res = APITest.create("/instances", {:image_id=>'wmi-lucid1', :instance_spec_id=>'is-demospec'})
    res.success?.should be_true
    instance_id = res["id"]
    retry_until do
      APITest.get("/instances/#{instance_id}")["state"] == "running"
    end
    APITest.delete("/instances/#{instance_id}").success?.should be_true
  end

  it "runs local store instance (wmi-lucid5,is-demospec) -> terminate" do
    res = APITest.create("/instances", {:image_id=>'wmi-lucid5', :instance_spec_id=>'is-demospec'})
    res.success?.should be_true
    instance_id = res["id"]
    retry_until do
      APITest.get("/instances/#{instance_id}")["state"] == "running"
    end
    APITest.delete("/instances/#{instance_id}").success?.should be_true
    
  end

  it "runs volume store instance (wmi-lucid6,is-demospec) -> terminate" do
    res = APITest.create("/instances", {:image_id=>'wmi-lucid6', :instance_spec_id=>'is-demospec'})
    res.success?.should be_true
    instance_id = res["id"]
    retry_until do
      APITest.get("/instances/#{instance_id}")["state"] == "running"
    end
    APITest.delete("/instances/#{instance_id}").success?.should be_true
  end
end
