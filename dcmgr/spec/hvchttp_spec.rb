require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::HvcHttp do
  include ActiveResourceHelperMethods

  before(:all) do
    reset_db
    @hvchttp = Dcmgr::HvcHttp.new
  end

  after(:all) do
    @hvchttp = Dcmgr::HvcHttpMock.new
  end

  it "should access" do
    @hvchttp.open('localhost', 19393) {|http|
      proc {
        # access POST "/" to public server
        http.get_response("/", {})
      }.should raise_error(RuntimeError) # not found
    }
  end
end
