
require File.expand_path('../spec_helper', __FILE__)

describe "/api/instances" do
  include InstanceHelper

  it "should run local store instance (wmi-lucid0,is-demospec) -> terminate" do
    run_instance_and_terminate({:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec', :ssh_key=>'demo'})
  end

  it "should run volume store instance (wmi-lucid1,is-demospec) -> terminate" do
    run_instance_and_terminate({:image_id=>'wmi-lucid1', :instance_spec_id=>'is-demospec', :ssh_key=>'demo'})
  end

  it "should run local store instance (wmi-lucid5,is-demospec) -> terminate" do
    run_instance_and_terminate({:image_id=>'wmi-lucid5', :instance_spec_id=>'is-demospec', :ssh_key=>'demo'})
  end

  it "should run volume store instance (wmi-lucid6,is-demospec) -> terminate" do
    run_instance_and_terminate({:image_id=>'wmi-lucid6', :instance_spec_id=>'is-demospec', :ssh_key=>'demo'})
  end

  private
  def run_instance_and_terminate(params)
    res = APITest.create("/instances", params)
    res.success?.should be_true
    instance_id = res["id"]

    retry_until_running(instance_id)
    retry_until_network_started(instance_id)
    retry_until_ssh_started(instance_id)

    case params[:image_id]
    when 'wmi-lucid0', 'wmi-lucid1' # without-metadata
      true
    when 'wmi-lucid5', 'wmi-lucid6' # with-metadata
      retry_until_loggedin(instance_id, 'ubuntu')
    end

    APITest.delete("/instances/#{instance_id}").success?.should be_true
    retry_until_terminated(instance_id)
  end

end
