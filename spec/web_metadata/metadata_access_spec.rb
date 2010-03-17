require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "metadeta access" do
  include ActiveResourceHelperMethods
  
  before(:all) do
    runserver(:private)
    @c = ar_class :Instance, :private=>true
  end
  
  it "should get by sh"
  it "should get by yaml"
  it "should get by json"

  it "should get latest"
end
