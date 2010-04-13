require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "image storage access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    @class = ar_class :ImageStorage
    image_storage_host_class = ar_class :ImageStorageHost
    @image_storage_host = image_storage_host_class.create
  end

  it "should upload image" do
    image_storage = @class.create(:image_storage_host=>@image_storage_host.id,
                          :storage_url=>'http://hoge')
    image_storage.id.length.should > 0
    ImageStorage[image_storage.id].should be_valid
    $image_storage_id = image_storage.id
  end
  
  it "should get list" do
    list = @class.find(:all)
    list.index { |obj| obj.id == $image_storage_id }.should be_true
  end
  
  it "should delete image" do
    id = $image_storage_id
    lambda {
      @class.find(id).destroy
    }.should change{ ImageStorage[id] }
  end

  it "should get by paging" do
    image_storages = (0...30).map{
      @class.create(:image_storage_host=>@image_storage_host.id,
                    :storage_url=>'http://hoge')
    }

    ret = @class.find(:all, :params=>{:limit=>3})
    ret.length.should == 3
    ret[0].id.should == ImageStorage.all[0].uuid
    ret[1].id.should == ImageStorage.all[1].uuid
    ret[2].id.should == ImageStorage.all[2].uuid

    ret = @class.find(:all, :params=>{:offset=>3})
    ret.length.should >= 27 # 30 - 3
    ret[0].id.should == ImageStorage.limit(1, 3).all.first.uuid
    ret[1].id.should == ImageStorage.limit(1, 4).all.first.uuid
    ret[2].id.should == ImageStorage.limit(1, 5).all.first.uuid

    ret = @class.find(:all, :params=>{:limit=>3, :offset=>10})
    ret.length.should == 3
    ret[0].id.should == ImageStorage.limit(1, 10).all.first.uuid
    ret[1].id.should == ImageStorage.limit(1, 11).all.first.uuid
    ret[2].id.should == ImageStorage.limit(1, 12).all.first.uuid
  end
end

