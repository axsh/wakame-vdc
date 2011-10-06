
require File.expand_path('../spec_helper', __FILE__)

describe "/api/host_pools" do

  it "should show host node list" do
    res = APITest.get("/host_pools")
    res.success?.should be_true
  end

  it "should describe host node (hp-demohost)" do
    host_id = "hp-demohost"
    res = APITest.get("/host_pools/#{host_id}")
    res["id"].should == host_id
    res.success?.should be_true
  end

end
