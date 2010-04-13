require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "active resource authorization" do
  include ActiveResourceHelperMethods
  before(:all) do
    @authuser = User.create(:name=>'__test_auth__', :password=>'passwd')
  end

  it "should authorize" do
    auth_tag_class = ar_class :NameTag, :user=>'__test_auth__', :password=>'passwd'
    tag = auth_tag_class.create(:name=>'name tag',
                                :account=>@account)
    tag.id.length.should > 0
  end
end

