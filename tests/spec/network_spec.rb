
require File.expand_path('../spec_helper', __FILE__)

describe "/api/networks" do

  it "should show network list" do
    res = APITest.get("/networks")
    res.success?.should be_true
  end

  it "should describe network (nw-demo1)" do
    network_id = "nw-demo1"
    res = APITest.get("/networks/#{network_id}")
    res["id"].should == network_id
    res.success?.should be_true
  end

end
