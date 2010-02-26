# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "frontend service users access by active resource" do
  include ActiveResourceHelperMethods

  it "should authorize by ip" do
    gui_server_c = ar_class(:FrontendServiceUser,
                            :user=>"gui")

    Dcmgr.fsuser_auth_type = :ip

    Dcmgr.fsuser_auth_users = {}
    proc {
      gui_server = gui_server_c.find(:myself)
    }.should raise_error(ActiveResource::UnauthorizedAccess)

    Dcmgr.fsuser_auth_users =
      {"192.168.1.10"=>"gui"}
    proc {
      gui_server = gui_server_c.find(:myself)
    }.should raise_error(ActiveResource::UnauthorizedAccess)

    Dcmgr.fsuser_auth_users =
      {"127.0.0.1"=>"gui"}
    user = gui_server_c.find(:myself)
    user.should be_valid
    user.name.should == "gui"
  end
  
  it "should authorize by basic auth"

  it "should authorize user"
end
