
require File.expand_path('../spec_helper', __FILE__)
require 'fileutils'

describe "1shot" do
  include RetryHelper
  include InstanceHelper

  it "tests CURD operations for 1shot" do
    timestamp = Time.now.strftime("%s")

    # ssh_key::create
    ssh_key_pair = APITest.create('/ssh_key_pairs.json', {:name=>"1shot.#{timestamp}"})
    ssh_key_pair.success?.should be_true
    sleep 3
    APITest.get("/ssh_key_pairs/#{ssh_key_pair["id"]}").success?.should be_true

    private_key_path = "/tmp/vdc_id_rsa.pem.#{timestamp}"
    open(private_key_path, "w") { |f| f.write(ssh_key_pair["private_key"]) }
    File.chmod(0600, private_key_path)

    # instance
    #instance = APITest.create("/instances", {:image_id=>'wmi-lucid5', :instance_spec_id=>'is-demospec', :"ssh_key"=>ssh_key_pair["name"]})
    instance = APITest.create("/instances", {:image_id=>'wmi-lucid6', :instance_spec_id=>'is-demospec', :"ssh_key"=>ssh_key_pair["name"]})
    instance.success?.should be_true
    instance_id = instance["id"]

    retry_until_running(instance_id)

    instance = APITest.get("/instances/#{instance_id}")
    ipv4 = instance["vif"].first["ipv4"]["address"]

    retry_until do
      `ping -c 1 -W 1 #{ipv4}`
      $?.exitstatus == 0
    end

    retry_until do
      `echo | nc #{ipv4} 22`
      $?.exitstatus == 0
    end

    sleep 3
    cmd = "ssh -o 'StrictHostKeyChecking no' -i #{private_key_path} ubuntu@#{ipv4} 'hostname; whoami;'"
    retry_until do
      `#{cmd}`
      $?.exitstatus == 0
    end

    `#{cmd}`
    $?.exitstatus.should == 0
    sleep 3

    APITest.delete("/instances/#{instance_id}").success?.should be_true
    retry_until_terminated(instance_id)

    # ssh_key::delete
    FileUtils.rm(private_key_path)
    APITest.delete("/ssh_key_pairs/#{ssh_key_pair["id"]}").success?.should be_true
  end
end
