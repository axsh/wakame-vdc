
require File.expand_path('../../spec_helper', __FILE__)

describe "bin/gui-manage user" do
  include CliHelper

  before :all do
    init_env
    cd_gui_dir
    @uuid = Time.now.strftime('%H%M%S')
  end

  it "should add accounts" do
    `./bin/gui-manage account add --name #{@uuid}1 -u a-#{@uuid}1`
    $?.exitstatus.should == 0
    `./bin/gui-manage account add --name #{@uuid}2 -u a-#{@uuid}2`
    $?.exitstatus.should == 0
  end

  it "should add user" do
    `./bin/gui-manage user add --name #{@uuid}0 -p #{@uuid}0 -u u-#{@uuid}0 #{@uuid}0`
    $?.exitstatus.should == 0
  end

  it "should associate user" do
    `./bin/gui-manage user associate u-#{@uuid}0 -a a-#{@uuid}1 a-#{@uuid}2`
    $?.exitstatus.should == 0
  end

  it "should delete user" do
    `./bin/gui-manage user del u-#{@uuid}0`
    $?.exitstatus.should == 0
  end

  it "should delete accounts" do
    `./bin/gui-manage account del a-#{@uuid}1`
    $?.exitstatus.should == 0
    `./bin/gui-manage account del a-#{@uuid}2`
    $?.exitstatus.should == 0
  end
end
