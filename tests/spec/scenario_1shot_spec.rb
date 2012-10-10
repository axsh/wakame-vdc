
require File.expand_path('../spec_helper', __FILE__)
require 'fileutils'
include Config

if is_enabled? :oneshot then
  cfg = get_config[:oneshot]
  describe "1shot" do
    include RetryHelper
    include InstanceHelper
    include NetfilterHelper
    include VolumeHelper

    before(:all) do
      @scenario_id = sprintf("scenario.%s", Time.now.strftime("%s"))
      @sg_res      = APITest.create('/security_groups', {:description => @scenario_id, :rule => cfg[:sg_rule]})
      @ssh_res     = APITest.create('/ssh_key_pairs', {})
      @inst_res    = APITest.create("/instances", {:image_id=>cfg[:image_id], :instance_spec_id=>cfg[:spec_id], :ssh_key_id=>@ssh_res["id"], :nf_group=>[@sg_res["id"]]})
      @vol_res     = APITest.create("/volumes", {:volume_size=>cfg[:volume_size]})
      retry_until do
        APITest.get("/volumes/#{@vol_res["id"]}")["state"] == "available"
      end if @vol_res.success?
      @snap_res    = APITest.create("/volume_snapshots", {:volume_id=>@vol_res["id"], :destination=>"local"})
      retry_until do
        APITest.get("/volume_snapshots/#{@snap_res["id"]}")["state"] == "available"
      end if @snap_res.success?
      @new_vol_res = APITest.create("/volumes", {:snapshot_id=>@snap_res["id"]})
      retry_until do
        APITest.get("/volumes/#{@new_vol_res["id"]}")["state"] == "available"
      end if @new_vol_res.success?
    end

    it "should create a security group" do
      @sg_res.success?.should be_true
    end

    it "should create an ssh key pair" do
      @ssh_res.success?.should be_true
    end

    it "should start an instance with the created security group and ssh key" do
      @inst_res.success?.should be_true
      instance_id = @inst_res["id"]

      #p '... retry_until_running'
      retry_until_running(instance_id)
      #p '... retry_until_network_started'
      retry_until_network_started(instance_id)
      #p '... retry_until_ssh_started'
      retry_until_ssh_started(instance_id)
      #p '... retry_until_loggedin'
      retry_until_loggedin(instance_id, cfg[:user_name])
    end

    it "should create a volume" do
      @vol_res.success?.should be_true
    end

    it "should attach the volume" do
      attach_volume_to_instance(@inst_res["id"],@vol_res["id"])
    end

    it "should detach the volume" do
      detach_volume_from_instance(@inst_res["id"],@vol_res["id"])
    end

    it "should create a snapshot from the volume" do
      @snap_res.success?.should be_true
    end

    it "should delete the volume" do
      delete_volume(@vol_res["id"])
    end

    it "should create a new volume from the snapshot" do
      @new_vol_res.success?.should be_true
    end

    it "should attach the new volume" do
      attach_volume_to_instance(@inst_res["id"],@new_vol_res["id"])
    end

    it "should detach the new volume" do
      detach_volume_from_instance(@inst_res["id"],@new_vol_res["id"])
    end

    it "should add rules to the security group" do
      cfg[:new_sg_rules].each { |rule|
        res = add_rules(@sg_res["id"], [rule])
        res.success?.should be_true
      }
    end

    it "should delete rules from the security group" do
      # delete rules
      (cfg[:new_sg_rules] + [cfg[:sg_rule]]).each { |rule|
        res = del_rules(@sg_res["id"], [rule])
        res.success?.should be_true
      }
    end

    it "should reboot the instance" do
      APITest.update("/instances/#{@inst_res["id"]}/reboot", []).success?.should be_true
      # TODO: proper check for rebooted instance. i.e. checking wtmp.
      sleep 5

      #p '... retry_until_network_started'
      retry_until_network_started(@inst_res["id"])
      #p '... retry_until_ssh_started'
      retry_until_ssh_started(@inst_res["id"])
      #p '... retry_until_loggedin'
      retry_until_loggedin(@inst_res["id"], cfg[:user_name])
    end

    it "should delete the new volume" do
      delete_volume(@new_vol_res["id"])
    end

    it "should delete the snapshot" do
      APITest.delete("/volume_snapshots/#{@snap_res["id"]}").success?.should be_true
      retry_until do
        # "available" -> "deleting" -> "deleted"
        APITest.get("/volume_snapshots/#{@snap_res["id"]}")["state"] == "deleted"
      end
    end

    it "should terminate the instance" do
      APITest.delete("/instances/#{@inst_res["id"]}").success?.should be_true
      retry_until_terminated(@inst_res["id"])
    end

    it "should delete the security group" do
      APITest.delete("/security_groups/#{@sg_res["id"]}").success?.should be_true
    end

    it "should delete the ssh key" do
      APITest.delete("/ssh_key_pairs/#{@ssh_res["id"]}").success?.should be_true
    end

  end
end
