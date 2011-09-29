
require File.expand_path('../spec_helper', __FILE__)
require 'fileutils'

describe "1shot" do
  include RetryHelper
  include InstanceHelper
  include NetfilterHelper

  it "should test CURD operations for 1shot" do
    scenario_id = sprintf("scenario.%s", Time.now.strftime("%s"))

    # netfilter::create
    netfilter_group_name = scenario_id
    res = APITest.create('/netfilter_groups', {:name => netfilter_group_name, :description => netfilter_group_name, :rule => "tcp:22,22,ip4:0.0.0.0/24"})
    res.success?.should be_true
    netfilter_group_id = res["uuid"]

    # ssh_key::create
    ssh_key_name = scenario_id
    res = APITest.create('/ssh_key_pairs', {:name=>ssh_key_name})
    res.success?.should be_true
    ssh_key_pair_id = res["id"]

    # instance::create
    res = APITest.create("/instances", {:image_id=>'wmi-lucid6', :instance_spec_id=>'is-demospec', :ssh_key=>ssh_key_name, :nf_group=>[netfilter_group_name]})
    res.success?.should be_true
    instance_id = res["id"]

    retry_until_running(instance_id)
    retry_until_network_started(instance_id)
    retry_until_ssh_started(instance_id)
    retry_until_loggedin(instance_id, 'ubuntu')

    # volume::create
    res = APITest.create("/volumes", {:volume_size=>10})
    res.success?.should be_true
    volume_id = res["id"]
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "available"
    end

    # volume:attach
    res = APITest.update("/volumes/#{volume_id}/attach", {:instance_id=>instance_id, :volume_id=>volume_id})
    res.success?.should be_true
    retry_until do
      # "available" -> "attaching" -> "attached"
      APITest.get("/volumes/#{volume_id}")["state"] == "attached"
    end

    # volume::detach
    res = APITest.update("/volumes/#{volume_id}/detach", {:instance_id=>instance_id, :volume_id=>volume_id})
    res.success?.should be_true
    retry_until do
      # "attached" -> "detaching" -> "available"
      APITest.get("/volumes/#{volume_id}")["state"] == "available"
    end

    # snap::create
    res = APITest.create("/volume_snapshots", {:volume_id=>volume_id, :destination=>"local"})
    snap_id = res["id"]
    res.success?.should be_true
    retry_until do
      APITest.get("/volume_snapshots/#{snap_id}")["state"] == "available"
    end

    # volume::delete
    APITest.delete("/volumes/#{volume_id}").success?.should be_true
    # "available" -> "deregistering" -> "deleted"
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
    end

    # volume::create from snapshot
    res = APITest.create("/volumes", {:snapshot_id=>snap_id})
    res.success?.should be_true
    volume_id = res["id"]
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "available"
    end

    # volume:attach
    res = APITest.update("/volumes/#{volume_id}/attach", {:instance_id=>instance_id, :volume_id=>volume_id})
    res.success?.should be_true
    retry_until do
      # "available" -> "attaching" -> "attached"
      APITest.get("/volumes/#{volume_id}")["state"] == "attached"
    end

    # volume::detach
    res = APITest.update("/volumes/#{volume_id}/detach", {:instance_id=>instance_id, :volume_id=>volume_id})
    res.success?.should be_true
    retry_until do
      # "attached" -> "detaching" -> "available"
      APITest.get("/volumes/#{volume_id}")["state"] == "available"
    end

    # netfilter::update
    # add rules
    res = add_rules(netfilter_group_id, ["tcp:80,80,ip4:0.0.0.0/24"])
    res.success?.should be_true

    res = add_rules(netfilter_group_id, ["icmp:-1,-1,ip4:0.0.0.0/24"])
    res.success?.should be_true

    # delete rules
    res = del_rules(netfilter_group_id, ["tcp:22,22,ip4:0.0.0.0/24"])
    res.success?.should be_true

    res = add_rules(netfilter_group_id, ["tcp:80,80,ip4:0.0.0.0/24"])
    res.success?.should be_true

    res = add_rules(netfilter_group_id, ["icmp:-1,-1,ip4:0.0.0.0/24"])
    res.success?.should be_true

    # volume::delete
    APITest.delete("/volumes/#{volume_id}").success?.should be_true
    # "available" -> "deregistering" -> "deleted"
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
    end

    # snap::delete
    APITest.delete("/volume_snapshots/#{snap_id}").success?.should be_true
    retry_until do
      # "available" -> "deleting" -> "deleted"
      APITest.get("/volume_snapshots/#{snap_id}")["state"] == "deleted"
    end

    # instance::delete
    APITest.delete("/instances/#{instance_id}").success?.should be_true
    retry_until_terminated(instance_id)

    # netfilter::delete
    APITest.delete("/netfilter_groups/#{netfilter_group_id}").success?.should be_true

    # ssh_key::delete
    APITest.delete("/ssh_key_pairs/#{ssh_key_pair_id}").success?.should be_true
  end

end
