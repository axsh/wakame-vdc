require 'spec_helper'

describe "InstancesController" do
  before do
    get "/"
  end

  it "returns hello world" do
    last_response.body.should == "Hello World"
  end
end
