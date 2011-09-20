
require File.expand_path('../../spec_helper', __FILE__)

describe "bin/gui-manage user" do
  include CliHelper

  before :all do
    init_env
    cd_gui_dir
    @uuid = Time.now.strftime('%H%M%S')
  end

  it "add user" do
    `./bin/gui-manage user add --name #{@uuid} -p #{@uuid} -u u-#{@uuid} #{@uuid}`
    $?.exitstatus.should == 0
  end

  it "show user" do
    `./bin/gui-manage user show u-#{@uuid}`
    $?.exitstatus.should == 0
  end

  it "delete user" do
    `./bin/gui-manage user del u-#{@uuid}`
    $?.exitstatus.should == 0
  end

  it "re-add user" do
    `./bin/gui-manage user add --name #{@uuid} -p #{@uuid} -u u-#{@uuid} #{@uuid}`
    $?.exitstatus.should == 0
  end

  it "re-delete user" do
    `./bin/gui-manage user del u-#{@uuid}`
    $?.exitstatus.should == 0
  end
end
