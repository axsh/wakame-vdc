require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../client/client')

describe "run instance access by active resource" do
  include ActiveResourceHelperMethods

  it "should access by Dcmgr::Client" do
    Dcmgr::Client::Base.site = 'http://localhost:19393'
    Dcmgr::Client::Base.user_uuid = User[1].uuid

    instance = Dcmgr::Client::Instance.create(:action_name=>'run',
                                              :account=>Account[1].uuid,
                                              :need_cpus=>1,
                                              :need_cpu_mhz=>0.5,
                                              :need_memory=>512,
                                              :image_storage=>ImageStorage[1].uuid)
    instance.should be_valid
  end

  it "should raise UnauthorizedAccess" do
    Dcmgr::Client::Base.site = 'http://localhost:19393'
    
    Dcmgr::Client::Base.user_uuid = "U-"

    proc {
      Dcmgr::Client::Instance.create(:action_name=>'run',
                                     :account=>Account[1].uuid,
                                     :need_cpus=>1,
                                     :need_cpu_mhz=>0.5,
                                     :need_memory=>512,
                                     :image_storage=>ImageStorage[1].uuid)
    }.should raise_error(ActiveResource::UnauthorizedAccess)
  end
  
  it "should run/shutdown instance(sample code)" do
    reset_db

    user_name = "user_a"
    password = "pass"

    # user
    user = ar_class(:User).create(:name=>user_name, :password=>password)
    user.should be_valid
    user.name.should == user_name

    # option for change user
    ar_opts = {:user=>user_name, :password=>password}

    # change user
    user = ar_class(:User, ar_opts).find(:myself)
    user.name.should == user_name
    lambda {
      user.password
    }.should raise_error(NoMethodError)

    # mapping account
    account = ar_class(:Account, ar_opts).create
    account.should be_valid

    # key pair
    keypair = ar_class(:KeyPair, ar_opts).create
    keypair.private_key.length.should > 0
    keypair.public_key.length.should > 0
    
    # select image
    images = ar_class(:ImageStorage, ar_opts).find(:all)
    images.length.should > 0
    select_image = images[0]

    # run instance
    instance_c = ar_class(:Instance, ar_opts)
    instance = instance_c.create(:account=>account.id,
                                 :need_cpus=>1, :need_cpu_mhz=>0.5,
                                 :need_memory=>1000,
                                 :image_storage=>select_image.id,
                                 :keyparir=>keypair.id)
    instance.should be_valid

    # terminate instance
    instance.put(:shutdown)

    # log
    date = Time.now
    log_c = ar_class(:Log, ar_opts)
    log_c.find(:all, :params=>{
                 :account=>account.id,
                 :year=>date.year, :month=>date.month})

    # account log
    log_c = ar_class(:Log, ar_opts)
    log_c.find(:all, :params=>{
                 :account=>account.id,
                 :year=>date.year, :month=>date.month})
  end
end

