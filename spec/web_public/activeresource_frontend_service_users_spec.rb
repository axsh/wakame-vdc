# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "frontend service users access by active resource" do
  include ActiveResourceHelperMethods

  it "should authorize by ip" do
    Dcmgr.fsuser_auth_type = :ip
    Dcmgr.fsuser_auth_users =
      [{:user=>"gui_server", :ip=>"127.0.0.1"},
       {:user=>"web_api", :ip=>"192.168.1.101"},]

    gui_server_c = ar_class(:FrontendServiceUser,
                                :user=>"gui")
    gui_server = gui_server_c.find(:myself)
    gui_server.should be_valid
  end
  
  it "should authorize by basic auth"

  it "should authorize user"
end
