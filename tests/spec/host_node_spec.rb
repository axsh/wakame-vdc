
require File.expand_path('../spec_helper', __FILE__)

describe "/api/host_nodes" do

  it "should show host node list" do
    res = APITest.get("/host_nodes")
    res.success?.should be_true
  end

  it "should describe host node (hn-demo1)" do
    host_id = "hn-demo1"
    res = APITest.get("/host_nodes/#{host_id}")
    res["id"].should == host_id
    res.success?.should be_true
  end

end
