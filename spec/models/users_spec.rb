# -*- coding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  before(:all) do
    @user_a = User.create(:name=>'user a', :password=>'p1')
    @user_b = User.create(:name=>'user b', :password=>'p2')
  end

  it "should default user fields" do
    @user_a.enable.should be_true
    @user_b.enable.should be_true

    @user_b.enable = false
    @user_b.save
    @user_b.reload
    @user_b.enable.should be_false
  end
    
  it "should be get only enable users" do
    User.all.index{|u| u.id == @user_a.id}.should be_true
    User.all.index{|u| u.id == @user_b.id}.should be_true

    enable_users = User.enable_users.all
    enable_users.index{|u| u.id == @user_a.id}.should be_true
    enable_users.index{|u| u.id == @user_b.id}.should be_false
  end
end
