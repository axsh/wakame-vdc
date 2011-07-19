
require File.expand_path('../spec_helper', __FILE__)

describe "/api/ssh_key_pair" do
  it "tests CURD operations for key pair" do
    res = APITest.post('/ssh_key_pairs.json', :query=>{:name=>'yyy'}, :body=>'')
  end
end
