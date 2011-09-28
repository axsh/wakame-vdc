
require File.expand_path('../../spec_helper', __FILE__)

describe "bin/gui-manage account" do
  include CliHelper

  before :all do
    init_env
    cd_gui_dir
    @uuid = Time.now.strftime('%H%M%S')
  end

  it "should not show account" do
    `./bin/gui-manage account show a-#{@uuid}`
    $?.exitstatus.should == 1
  end

  it "should add account" do
    `./bin/gui-manage account add --name #{@uuid} -u a-#{@uuid}`
    $?.exitstatus.should == 0
  end

  it "should show account" do
    `./bin/gui-manage account show a-#{@uuid}`
    $?.exitstatus.should == 0
  end

  it "should not re-add new account with used uuid." do
    `./bin/gui-manage account add --name #{@uuid} -u a-#{@uuid}`
    $?.exitstatus.should == 101
  end

  it "should create/show oauth key and secret." do
    `./bin/gui-manage account oauth a-#{@uuid}`
    $?.exitstatus.should == 0
  end

  it "should delete account" do
    `./bin/gui-manage account del a-#{@uuid}`
    $?.exitstatus.should == 0
  end

  it "should not re-add new account with deleted uuid." do
    `./bin/gui-manage account add --name #{@uuid} -u a-#{@uuid}`
    $?.exitstatus.should == 101
  end

  it "should not create/show oauth key and secret." do
    `./bin/gui-manage account oauth a-#{@uuid}`
    $?.exitstatus.should == 100
  end

end
