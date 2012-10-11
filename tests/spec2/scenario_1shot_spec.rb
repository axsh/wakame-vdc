require File.expand_path('../spec_helper', __FILE__)

describe "1shot" do

  include RetryHelper
  include InstanceHelper
  include NetfilterHelper
  include VolumeHelper

  before(:all) do
    @scenario_id = sprintf("scenario.%s", Time.now.strftime("%s"))
    p ".. create security groups"
    @sg_res = Hash.new
    @sg_res[:sg1] = APITest.create('/security_groups', {:description => @scenario_id, :rule => "tcp:22,22,ip4:0.0.0.0\nicmp:-1,-1,ip4:0.0.0.0"})
    @sg_res[:sg2] = APITest.create('/security_groups', {:description => @scenario_id, :rule => "tcp:22,22,ip4:0.0.0.0"})

    p ".. create ssh key pairs"
    @ssh_res = Hash.new
    @ssh_res[:ssh1] = APITest.create('/ssh_key_pairs', {})
    @ssh_res[:ssh2] = APITest.create('/ssh_key_pairs', {})

    p ".. create instances"
    @inst_res = Hash.new
    @inst_res[:inst1] = APITest.create('/instances', {:host_id => 'hn-demo18', :image_id => 'wmi-lucid5', :instance_spec_id => 'is-demospec', :ssh_key_id => @ssh_res[:ssh1]["id"], :nf_group => [@sg_res[:sg1]["id"]]})
    @inst_res[:inst2] = APITest.create('/instances', {:host_id => 'hn-demo19', :image_id => 'wmi-lucid5', :instance_spec_id => 'is-demospec', :ssh_key_id => @ssh_res[:ssh1]["id"], :nf_group => [@sg_res[:sg2]["id"]]})
    @inst_res[:inst3] = APITest.create('/instances', {:host_id => 'hn-demo20', :image_id => 'wmi-lucid5', :instance_spec_id => 'is-demospec', :ssh_key_id => @ssh_res[:ssh2]["id"], :nf_group => [@sg_res[:sg1]["id"]]})

    p ".. create volumes"
    @vol_res = Hash.new
    @vol_res[:vol1] = APITest.create("/volumes", {:volume_size => 10})
    @vol_res[:vol2] = APITest.create("/volumes", {:volume_size => 10})
    @vol_res[:vol3] = APITest.create("/volumes", {:volume_size => 10})
    @vol_res.values.each { |vol|
      retry_until_available(:volumes, vol["id"])
    }

    p ".. create volume snapshots"
    @snap_res = APITest.create("/volume_snapshots", {:volume_id => @vol_res[:vol1]["id"], :destination => "local"})
    retry_until_available(:volume_snapshots, @snap_res["id"])

    p ".. create volumes from snapshots"
    @new_vol_res = APITest.create("/volumes", {:snapshot_id => @snap_res["id"]})
    retry_until_available(:volumes, @new_vol_res["id"])
  end

  it "should create security groups" do
    @sg_res.values.each { |sg|
      sg.success?.should be_true
    }
  end

  it "should create ssh key pairs" do
    @ssh_res.values.each { |ssh|
      ssh.success?.should be_true
    }
  end

  it "should start instances with the created security group and ssh key" do
    @inst_res.values.each { |inst|
      inst.success?.should be_true
      retry_until_running(inst["id"])
    }
  end

  it "should confirmed security group" do
    retry_until_network_started(@inst_res[:inst1]["id"])
    retry_until_network_started(@inst_res[:inst3]["id"])
  end

  it "should not confirmed security group" do
    retry_until_network_stopped(@inst_res[:inst2]["id"])
  end

  it "should ssh key login" do
    @inst_res.values.each { |inst|
      retry_until_ssh_started(inst["id"])
      retry_until_loggedin(inst["id"], "ubuntu")
    }
  end

  it "should add rules to the security group" do
    res = add_rules(@sg_res[:sg2]["id"], ["icmp:-1,-1,ip4:0.0.0.0"])
    res.success?.should be_true
  end

  it "should security group comfirmed" do
    retry_until_network_started(@inst_res[:inst2]["id"])
  end

  it "should delete rules from security group" do
    res = del_rules(@sg_res[:sg2]["id"], ["icmp:-1,-1,ip4:0.0.0.0"])
    res.success?.should be_true
  end

  it "should not security group comfirmed" do
    retry_until_network_stopped(@inst_res[:inst2]["id"])
  end

  it "should create volumes" do
    @vol_res.values.each { |vol|
      vol.success?.should be_true
    }
  end

  it "should attach the volume" do
    attach_volume_to_instance(@inst_res[:inst1]["id"], @vol_res[:vol1]["id"])
    attach_volume_to_instance(@inst_res[:inst2]["id"], @vol_res[:vol2]["id"])
    attach_volume_to_instance(@inst_res[:inst3]["id"], @vol_res[:vol3]["id"])
  end

  it "should detach the volume" do
    detach_volume_from_instance(@inst_res[:inst1]["id"], @vol_res[:vol1]["id"])
    detach_volume_from_instance(@inst_res[:inst2]["id"], @vol_res[:vol2]["id"])
    detach_volume_from_instance(@inst_res[:inst3]["id"], @vol_res[:vol3]["id"])
  end

  it "should create a snapshot from the volume" do
    @snap_res.success?.should be_true
  end

  it "should create a new volume from snapshot" do
    @new_vol_res.success?.should be_true
  end

  it "should delete the new volume" do
    delete_volume(@new_vol_res["id"])
  end

  it "should delete snapshot" do
    delete_snapshot(@snap_res["id"])
  end

  it "should delete volumes" do
    @vol_res.values.each { |vol|
      delete_volume(vol["id"])
    }
  end

  it "should terminate the instance" do
    @inst_res.values.each { |inst|
      APITest.delete("/instances/#{inst["id"]}").success?.should be_true
      retry_until_terminated(inst["id"])
    }
  end

  it "should delete the security groups" do
    @sg_res.values.each { |sg|
      APITest.delete("/security_groups/#{sg["id"]}").success?.should be_true
    }
  end

  it "should delete the ssh key pairs" do
    @ssh_res.values.each { |ssh|
      APITest.delete("/ssh_key_pairs/#{ssh["id"]}").success?.should be_true
    }
  end
end
