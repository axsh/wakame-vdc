
require File.expand_path('../spec_helper', __FILE__)

describe "/api/instances" do
  include InstanceHelper

  # parameters
  #
  # o param :image_id, string, :required
  # o param :instance_spec_id, string, :required
  # - param :host_id, string, :optional # not implemented yet
  # o param :hostname, string, :optional
  # o param :user_data, string, :optional
  # o param :nf_group, array, :optional
  # o param :ssh_key_id, string, :optional
  # - param :network_id, string, :optional # not implemented yet
  # o param :ha_enabled, string, :optional

  # ssh_key and nf_group
  it "should run instance with ssh_key and nf_group" do
    run_instance_then_reboot_then_terminate({:host_id => 'hn-demo18', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                                              :ssh_key_id => 'ssh-demo', :nf_group => 'sg-demofgr'})
  end

  # hostname
  it "should run instance with hostname (min length:1)" do
    run_instance_then_reboot_then_terminate({:host_id => 'hn-demo19', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                                              :nf_group => 'sg-demofgr', :hostname=>'0'})
  end

  it "should run instance with hostname (max length:32)" do
    run_instance_then_reboot_then_terminate({:host_id => 'hn-demo20', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                                              :nf_group => 'sg-demofgr', :hostname=>'01234567890123456789012345678901'})
  end

  it "should not run instance with hostname (less than min length:1)" do
    APITest.create("/instances", {:host_id => 'hn-demo18', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                     :nf_group => 'sg-demofgr', :hostname=>''}).success?.should_not be_true
  end

  it "should not run instance with hostname (more than max length:32)" do
    APITest.create("/instances", {:host_id => 'hn-demo19', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                     :nf_group => 'sg-demofgr', :hostname=>'012345678901234567890123456789012'}).success?.should_not be_true
  end

  it "should not run instance with invalid hostname" do
    APITest.create("/instances", {:host_id => 'hn-demo20', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                     :nf_group => 'sg-demofgr', :hostname=>'!'}).success?.should_not be_true
    APITest.create("/instances", {:host_id => 'hn-demo18', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                     :nf_group => 'sg-demofgr', :hostname=>'#'}).success?.should_not be_true
    APITest.create("/instances", {:host_id => 'hn-demo19', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                     :nf_group => 'sg-demofgr', :hostname=>'_'}).success?.should_not be_true
    APITest.create("/instances", {:host_id => 'hn-demo20', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                     :nf_group => 'sg-demofgr', :hostname=>'*'}).success?.should_not be_true
  end

  # user_data
  it "should run instance with user_data" do
    run_instance_then_reboot_then_terminate({:host_id => 'hn-demo18', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                                              :nf_group => 'sg-demofgr', :user_data => "user_data value"})
  end

  # ha_enabled
  it "should run instance with ha_enabled" do
    run_instance_then_reboot_then_terminate({:host_id => 'hn-demo19', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                                              :nf_group => 'sg-demofgr', :ha_enabled => 'true'})
    run_instance_then_reboot_then_terminate({:host_id => 'hn-demo20', :image_id=> 'wmi-lucid5', :instance_spec_id=> 'is-demospec',
                                              :nf_group => 'sg-demofgr', :ha_enabled => 'false'})
  end

  private
  def run_instance_then_reboot_then_terminate(params)
    p ".. create instance"
    res = APITest.create("/instances", params)
    res.success?.should be_true
    instance_id = res["id"]

    p ".. retry until runnning"
    retry_until_running(instance_id)

    if params[:nf_group]
      p ".. retry until network and ssh started"
      retry_until_network_started(instance_id)
      retry_until_ssh_started(instance_id)
    end

    if params[:ssh_key_id]
      p ".. retry until ssh started"
      retry_until_loggedin(instance_id, 'ubuntu')
    end

    p ".. reboot instance #{instance_id}"
    APITest.update("/instances/#{instance_id}/reboot", []).success?.should be_true
    # TODO: proper check for rebooted instance. i.e. checking wtmp.
    sleep 5

    p ".. delete instance #{instance_id}"
    APITest.delete("/instances/#{instance_id}").success?.should be_true
    retry_until_terminated(instance_id)
  end

end

