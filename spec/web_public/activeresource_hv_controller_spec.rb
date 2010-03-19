require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "hvc access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = ar_class :HvController
  end

  it "should add" do
    hvc = @class.create(:access_url=>'http://localhost/')
    hvc.id.length.should > 0
    HvController[hvc.id].should be_valid
    $hvc = hvc
  end
  
  it "should delete" do
    id = $hvc.id
    lambda {
      $hvc.destroy
    }.should change{ HvController[id] }
  end
end

