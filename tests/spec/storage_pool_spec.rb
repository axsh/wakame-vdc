
require File.expand_path('../spec_helper', __FILE__)

describe "/api/storage_pools" do

  it "should show storage node list" do
    res = APITest.get("/storage_pools")
    res.success?.should be_true
  end

  it "should describe storage node (sp-demostor)" do
    storage_id = "sp-demostor"
    res = APITest.get("/storage_pools/#{storage_id}")
    res["id"].should == storage_id
    res.success?.should be_true
  end

end
