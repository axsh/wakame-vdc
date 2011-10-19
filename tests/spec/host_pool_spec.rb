
require File.expand_path('../spec_helper', __FILE__)

describe "/api/host_pools" do

  it "should show host node list" do
    res = APITest.get("/host_pools")
    res.success?.should be_true
  end

  it "should describe host node (hp-demo1)" do
    host_id = "hp-demo1"
    res = APITest.get("/host_pools/#{host_id}")
    res["id"].should == host_id
    res.success?.should be_true
  end

end
