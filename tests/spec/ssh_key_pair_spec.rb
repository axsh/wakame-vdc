
require File.expand_path('../spec_helper', __FILE__)

describe "/api/ssh_key_pair" do

  it "should show key pair list" do
    res = APITest.get("/ssh_key_pairs")
    res.success?.should be_true
  end

  it "should test CURD operations for key pair" do
    res = APITest.create('/ssh_key_pairs', {})
    res.success?.should be_true
    APITest.get("/ssh_key_pairs/#{res["id"]}").success?.should be_true
    APITest.delete("/ssh_key_pairs/#{res["id"]}").success?.should be_true
  end

end
