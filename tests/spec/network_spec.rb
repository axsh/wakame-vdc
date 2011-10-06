
require File.expand_path('../spec_helper', __FILE__)

describe "/api/networks" do

  it "should show network list" do
    res = APITest.get("/networks")
    res.success?.should be_true
  end

  it "should describe network (nw-demonet)" do
    network_id = "nw-demonet"
    res = APITest.get("/networks/#{network_id}")
    res["id"].should == network_id
    res.success?.should be_true
  end

end
