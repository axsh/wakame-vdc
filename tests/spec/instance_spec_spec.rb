
require File.expand_path('../spec_helper', __FILE__)

describe "/api/instance_specs" do

  it "should should show instance_spec list" do
    res = APITest.get("/instance_specs")
    res.success?.should be_true
  end

  it "should describe instance_spec (is-demospec)" do
    spec_id = "is-demospec"
    res = APITest.get("/instance_specs/#{spec_id}")
    res["id"].should == spec_id
    res.success?.should be_true
  end

end
