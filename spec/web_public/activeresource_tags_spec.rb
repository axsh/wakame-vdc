require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "tags access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db

    @name_c = ar_class :NameTag
    @auth_c = ar_class :AuthTag

    @attribute_c = ar_class :TagAttribute

    account_c = ar_class :Account
    @account = account_c.create(:name=>'test account by instance spec')
  end

  it "should add name tag" do
    tag = @name_c.create(:name=>'name tag #1', :account=>@account.id)
    tag.id.length.should > 0

    real_tag = Tag[tag.id]
    real_tag.should be_valid
    real_tag.account.uuid.should == @account.id
    real_tag.name.should == 'name tag #1'

    real_tagattribute = real_tag.tag_attribute
    real_tagattribute.should be_nil
    
    $tag = tag
  end
  
  it "should delete name tag" do
    id = $tag.id
    $tag.destroy
    Tag[id].should be_nil
  end
  
  it "should add simple auth tag" do
    tag = @auth_c.create(:name=>'instance crud tag #1',
                             :role=>"ABCD1234",
                             :tags=>[],
                             :account=>@account.id)
    tag.id.length.should > 0

    real_tag = Tag[tag.id]
    real_tag.should be_valid
    real_tag.account.uuid.should == @account.id
    real_tag.name.should == 'instance crud tag #1'
    real_tag.tag_mappings.length.should == 0

    real_tagattribute = real_tag.tag_attribute
    real_tagattribute.should be_valid
    real_tagattribute.role.should == "ABCD1234"
    
    $auth_tag = tag
  end
  
  it "should delete auth tag" do
    $auth_tag.destroy
    Tag[$auth_tag.id].should be_nil
  end
  
  
  it "should add auth tag that includes name tags" do
    tag1 = @name_c.create(:name=>'name tag #2-1', :account=>@account.id)
    tag2 = @name_c.create(:name=>'name tag #2-2', :account=>@account.id)
    tag3 = @name_c.create(:name=>'name tag #2-3', :account=>@account.id)
    
    tag = @auth_c.create(:name=>'instance crud tag #2',
                             :role=>"ABCD1234",
                             :tags=>[tag1.id, tag2.id, tag3.id],
                             :account=>@account.id)
    tag.id.length.should > 0

    real_tag = Tag[tag.id]
    real_tag.should be_valid
    real_tag.account.uuid.should == @account.id
    real_tag.role.should == "ABCD1234"
    real_tag.name.should == 'instance crud tag #2'
    real_tag.tag_mappings.length.should == 3

    real_tagattribute = real_tag.tag_attribute
    real_tagattribute.should be_valid
    real_tagattribute.role.should == "ABCD1234"
  end

  it "should store tag attribute" do
    tag = @name_c.create(:name=>'name tag #2-1', :account=>@account.id)

    attribute = @attribute_c.find(tag.id)
    attribute.body = 'x' * 100
    attribute.save

    real_attribute = Tag[tag.id].tag_attribute
    real_attribute.body.should == 'x' * 100
  end

  it "should get tag attribute" do
    tag = @name_c.create(:name=>'name tag #2-1', :account=>@account.id)

    TagAttribute.create(:tag=>Tag[tag.id],
                        :body=>'y'*100)

    attribute = @attribute_c.find(tag.id)
    attribute.body.should == 'y' * 100
  end
end

