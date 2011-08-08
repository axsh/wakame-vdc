
require File.expand_path('../spec_helper', __FILE__)

describe "/api/ssh_key_pair" do
  it "tests CURD operations for key pair" do
    res = APITest.create('/ssh_key_pairs.json', {:name=>'yyy'})
    res.success?.should be_true
    APITest.get("/ssh_key_pairs/#{res["id"]}").success?.should be_true
    APITest.delete("/ssh_key_pairs/#{res["id"]}").success?.should be_true
  end
end
