
require File.expand_path('../spec_helper', __FILE__)

describe "/api/storage_nodes" do

  it "should show storage node list" do
    res = APITest.get("/storage_nodes")
    res.success?.should be_true
  end

  it "should describe storage node (sp-demostor)" do
    storage_id = "sn-demo1"
    res = APITest.get("/storage_nodes/#{storage_id}")
    res["id"].should == storage_id
    res.success?.should be_true
  end

end
