# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "frontend service users access by active resource" do
  include ActiveResourceHelperMethods

  it "should authorize by ip" do
    gui_server_c = ar_class_with_basicauth(:FrontendServiceUser)

    Dcmgr.fsuser_auth_type = :ip

    Dcmgr.fsuser_auth_users = {}
    proc {
      gui_server = gui_server_c.find(:myself)
    }.should raise_error(ActiveResource::UnauthorizedAccess)

    Dcmgr.fsuser_auth_users =
      {"gui"=>"192.168.1.10"}
    proc {
      gui_server = gui_server_c.find(:myself)
    }.should raise_error(ActiveResource::UnauthorizedAccess)

    Dcmgr.fsuser_auth_users =
      {"gui"=>"127.0.0.1"}
    user = gui_server_c.find(:myself)
    user.should be_valid
    user.name.should == "gui"
  end
  
  it "should authorize by basic auth" do
    gui_server_c = ar_class_with_basicauth(:FrontendServiceUser,
                                   :user=>"gui",
                                   :password=>"password")

    Dcmgr.fsuser_auth_type = :basic

    Dcmgr.fsuser_auth_users = {}
    proc {
      gui_server = gui_server_c.find(:myself)
    }.should raise_error(ActiveResource::UnauthorizedAccess)

    Dcmgr.fsuser_auth_users =
      {"gui"=>"bad_password"}
    proc {
      gui_server = gui_server_c.find(:myself)
    }.should raise_error(ActiveResource::UnauthorizedAccess)

    Dcmgr.fsuser_auth_users =
      {"gui"=>"password"}
    user = gui_server_c.find(:myself)
    user.should be_valid
    user.name.should == "gui"
  end

  it "shouldn't set authorize type" do
    proc {
      Dcmgr.fsuser_auth_type = nil
    }.should raise_error(Dcmgr::FsuserAuthorizer::UnknownAuthType)
    proc {
      Dcmgr.fsuser_auth_type = :unknown_auth_type
    }.should raise_error(Dcmgr::FsuserAuthorizer::UnknownAuthType)
  end

  it "should authorize user" do
    gui_server_c = ar_class_with_basicauth(:FrontendServiceUser)

    Dcmgr.fsuser_auth_type = :ip
    Dcmgr.fsuser_auth_users =
      {"gui"=>"127.0.0.1"}

    user = gui_server_c.get(:authorize,
                            :user=>'__test__',
                            :password=>'passwd')
    user.should be_instance_of Hash
    user["name"].should == '__test__'
    user["id"].should == User.find(:name=>'__test__').uuid
  end

  it "should access other ar class" do
    gui_server_c = ar_class_with_basicauth(:FrontendServiceUser)
    gui_server_c = ar_class_with_basicauth(:FrontendServiceUser)

    Dcmgr.fsuser_auth_type = :ip
    Dcmgr.fsuser_auth_users =
      {"gui"=>"10.1.1.1"}

    proc {
      account = ar_class(:Account).create
    }.should raise_error(NoMethodError)

    Dcmgr.fsuser_auth_users =
      {"gui"=>"127.0.0.1"}

    account = ar_class(:Account).create
  end
end
