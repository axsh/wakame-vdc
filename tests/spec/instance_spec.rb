
require File.expand_path('../spec_helper', __FILE__)

describe "/api/instances" do
  include InstanceHelper

  # basic machine images
  it "should run local store instance (wmi-lucid0,is-demospec) -> reboot -> terminate" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec', :ssh_key=>'demo'})
  end

  it "should run volume store instance (wmi-lucid1,is-demospec) -> reboot -> terminate" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid1', :instance_spec_id=>'is-demospec', :ssh_key=>'demo'})
  end

  it "should run local store instance (wmi-lucid5,is-demospec) -> reboot -> terminate" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid5', :instance_spec_id=>'is-demospec', :ssh_key=>'demo'})
  end

  it "should run volume store instance (wmi-lucid6,is-demospec) -> reboot -> terminate" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid6', :instance_spec_id=>'is-demospec', :ssh_key=>'demo'})
  end

  # parameters
  #
  # o param :image_id, string, :required
  # o param :instance_spec_id, string, :required
  # - param :host_id, string, :optional # not implemented yet
  # o param :hostname, string, :optional
  # o param :user_data, string, :optional
  # o param :nf_group, array, :optional
  # o param :ssh_key, string, :optional
  # - param :network_id, string, :optional # not implemented yet
  # o param :ha_enabled, string, :optional

  # ssh_key
  it "should run instance with ssh_key" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                                              :ssh_key=>'demo'})
  end

  # nf_group
  it "should run instance with nf_group" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                                              :nf_group=>['default']})
  end

  # hostname
  it "should run instance with hostname (min length:1)" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                                              :hostname=>'0'})
  end

  it "should run instance with hostname (max length:32)" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                                              :hostname=>'01234567890123456789012345678901'})
  end

  it "should not run instance with hostname (less than min length:1)" do
    APITest.create("/instances", {:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                     :hostname=>''}).success?.should_not be_true
  end

  it "should not run instance with hostname (more than max length:32)" do
    APITest.create("/instances", {:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                     :hostname=>'012345678901234567890123456789012'}).success?.should_not be_true
  end

  it "should not run instance with invalid hostname" do
    APITest.create("/instances", {:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                     :hostname=>'!'}).success?.should_not be_true
    APITest.create("/instances", {:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                     :hostname=>'#'}).success?.should_not be_true
    APITest.create("/instances", {:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                     :hostname=>'_'}).success?.should_not be_true
    APITest.create("/instances", {:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                     :hostname=>'*'}).success?.should_not be_true
  end

  # user_data
  it "should run instance with user_data" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                                              :user_data => "user_data value"})
  end

  # ha_enabled
  it "should run instance with ha_enabled" do
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                                              :ha_enabled => 'true'})
    run_instance_then_reboot_then_terminate({:image_id=>'wmi-lucid0', :instance_spec_id=>'is-demospec',
                                              :ha_enabled => 'false'})
  end

  describe "stop/start using wmi-lucid1 (volume store image)" do
    before do
      # Always bring new instance to running.
      res = APITest.create("/instances", {:image_id=>'wmi-lucid1', :instance_spec_id=>'is-demospec'})
      res.success?.should be_true
      @instance_id = res["id"]
      
      retry_until_running(@instance_id)
    end

    after do
      # Always try terminate
      
      APITest.delete("/instances/#{@instance_id}").success?.should be_true
      retry_until_terminated(@instance_id)
      # check volume state
      instance = APITest.get("/instances/#{@instance_id}")
      instance['volume'].each { |v|
        v['state'].should == 'available'
      }
    end

    def retry_until_stopped(instance_id)
      retry_until do
        case APITest.get("/instances/#{instance_id}")["state"]
        when 'stopped'
          true
        when 'terminated'
          raise "Instance terminated by the system due to failure."
        else
          false
        end
      end
    end
    
    it 'running -> stop -> terminate' do
      APITest.update("/instances/#{@instance_id}/stop", []).success?.should be_true
      retry_until_stopped(@instance_id)
      # check volume state
      instance = APITest.get("/instances/#{@instance_id}")
      instance['volume'].each { |v|
        v['state'].should == 'attached'
      }
    end
    
    it 'running -> stop -> running -> terminate' do
      APITest.update("/instances/#{@instance_id}/stop", []).success?.should be_true
      retry_until_stopped(@instance_id)
      APITest.update("/instances/#{@instance_id}/start", []).success?.should be_true
      retry_until_running(@instance_id)
    end
    
    it 'running -> stop -> running -> stop -> terminate' do
      APITest.update("/instances/#{@instance_id}/stop", []).success?.should be_true
      retry_until_stopped(@instance_id)
      APITest.update("/instances/#{@instance_id}/start", []).success?.should be_true
      retry_until_running(@instance_id)
      APITest.update("/instances/#{@instance_id}/stop", []).success?.should be_true
      retry_until_stopped(@instance_id)
    end
  end

  private
  def run_instance_then_reboot_then_terminate(params)
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

    APITest.update("/instances/#{instance_id}/reboot", []).success?.should be_true
    retry_until_network_stopped(instance_id)

    APITest.delete("/instances/#{instance_id}").success?.should be_true
    retry_until_terminated(instance_id)
  end

end
