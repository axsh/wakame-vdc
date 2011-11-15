
require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled? :instance_spec
  cfg = get_config[:instance_spec]

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

    # ssh_key
    it "should run instance with ssh_key" do
      run_instance_then_reboot_then_terminate({:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                                                :ssh_key=>cfg[:ssh_key]})
    end

    # nf_group
    it "should run instance with nf_group" do
      run_instance_then_reboot_then_terminate({:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                                                :nf_group=>cfg[:nf_group]})
    end

    # hostname
    it "should run instance with hostname (min length:1)" do
      run_instance_then_reboot_then_terminate({:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                                                :hostname=>'0'})
    end

    it "should run instance with hostname (max length:32)" do
      run_instance_then_reboot_then_terminate({:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                                                :hostname=>'01234567890123456789012345678901'})
    end

    it "should not run instance with hostname (less than min length:1)" do
      APITest.create("/instances", {:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                       :hostname=>''}).should_not be_true
    end

    it "should not run instance with hostname (more than max length:32)" do
      APITest.create("/instances", {:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                       :hostname=>'012345678901234567890123456789012'}).success?.should_not be_true
    end

    it "should not run instance with invalid hostname" do
      APITest.create("/instances", {:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                       :hostname=>'!'}).success?.should_not be_true
      APITest.create("/instances", {:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                       :hostname=>'#'}).success?.should_not be_true
      APITest.create("/instances", {:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                       :hostname=>'_'}).success?.should_not be_true
      APITest.create("/instances", {:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                       :hostname=>'*'}).success?.should_not be_true
    end

    # user_data
    it "should run instance with user_data" do
      run_instance_then_reboot_then_terminate({:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                                                :user_data => "user_data value"})
    end

    # ha_enabled
    it "should run instance with ha_enabled" do
      run_instance_then_reboot_then_terminate({:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                                                :ha_enabled => 'true'})
      run_instance_then_reboot_then_terminate({:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:instance_spec_id],
                                                :ha_enabled => 'false'})
    end

    it "Should have properly set the assigned parameters. (ssh_key, nf_group, hostname)" do
      res = APITest.create("/instances", cfg)
      res.success?.should be_true
      
      res["ssh_key_pair"].should == cfg[:ssh_key]
      res["netfilter_group"].eql?(cfg[:nf_group]).should be_true
      res["hostname"].should == cfg[:hostname]
      # We can't test user data because it's not returned by the web api
    end

    #TODO: Decide where to place this test
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

      #def retry_until_stopped(instance_id)
        #retry_until do
          #case APITest.get("/instances/#{instance_id}")["state"]
          #when 'stopped'
            #true
          #when 'terminated'
            #raise "Instance terminated by the system due to failure."
          #else
            #false
          #end
        #end
      #end
      
      it 'running -> stop -> terminate' do
        APITest.update("/instances/#{@instance_id}/stop", []).success?.should be_true
        retry_until_stopped(@instance_id)
        # check volume state
        instance = APITest.get("/instances/#{@instance_id}")
        instance['volume'].each { |v|
          v['state'].should == 'attached'
        }
        instance['ips'].nil?.should be_true
      end
      
      it 'running -> stop -> running -> terminate' do
        instance = APITest.get("/instances/#{@instance_id}")
        APITest.update("/instances/#{@instance_id}/stop", []).success?.should be_true
        retry_until_stopped(@instance_id)
        APITest.update("/instances/#{@instance_id}/start", []).success?.should be_true
        retry_until_running(@instance_id)
        # compare differences of parameters to the old one.
        new_instance = APITest.get("/instances/#{@instance_id}")
        instance['vif'].first['vif_id'].should == new_instance['vif'].first['vif_id']
        instance['vif'].first['ipv4']['address'].should_not == new_instance['vif'].first['ipv4']['address']
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

    describe "Multiple network interface support" do
      it 'run instance with vif3type1 network strategy' do
        # Always bring new instance to running.
        res = APITest.create("/instances", {:image_id=>'wmi-lucid1', :instance_spec_id=>'is-demo2', :network_scheduler=>'vif3type1'})
        res.success?.should be_true
        @instance_id = res["id"]
        
        retry_until_running(@instance_id)

        APITest.delete("/instances/#{@instance_id}").success?.should be_true
        retry_until_terminated(@instance_id)
      end

      it 'run instance with vif3type2 network strategy' do
        # Always bring new instance to running.
        res = APITest.create("/instances", {:image_id=>'wmi-lucid1', :instance_spec_id=>'is-demo2', :network_scheduler=>'vif3type2'})
        res.success?.should be_true
        @instance_id = res["id"]
        
        retry_until_running(@instance_id)

        APITest.delete("/instances/#{@instance_id}").success?.should be_true
        retry_until_terminated(@instance_id)
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
      # TODO: proper check for rebooted instance. i.e. checking wtmp.
      sleep 5

      APITest.delete("/instances/#{instance_id}").success?.should be_true
      retry_until_terminated(instance_id)
    end

  end
end
