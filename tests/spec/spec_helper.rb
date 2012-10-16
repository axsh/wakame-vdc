
require 'rubygems'
require 'bundler/setup' rescue nil
require 'httparty'
require 'json'
require 'fileutils'

require 'rspec'

require 'shared_examples'

module Config
  DEFAULT_CONFIG_FILE=File.expand_path('../config/config.yml', __FILE__)
  def get_config
    ConfigFactory.create_config
  end

  # Determines whether or not the tests are
  # suppposed to be run or not.
  def is_enabled?(test)
    not get_config[test].nil?
  end

  class ConfigFactory
    def self.create_config(*args)
      # Check if a config file was specified
      # If not, we try the default location
      cfg_file = (not args[0].nil?) && File.exists?(args[0]) ? args[0] : DEFAULT_CONFIG_FILE
      begin
        YAML.load_file cfg_file
      rescue Errno::ENOENT => e
        # If there was no config file, we use
        # the default configuration

        puts "Warning: #{cfg_file} not found. Falling back to default configuration."
        default_config
      end
    end

    private
    # Returns a hard coded configuration for testing a standard vdc.sh environment
    def self.default_config
      {
        :global => {
          :retry_time => 5, # Retry time in minutes
          :account => "a-shpoolxx",
          :api => "http://localhost:9001/api"
        },

        # Spec that tests machine images
        # Tests if instances start from them and if we can SSH into them
        # Also tests start and stop operations
        :images_spec => {
          :images => [
            {:id=>"wmi-lucid0",:user=>"ubuntu",:uses_metadata => false},
            {:id=>"wmi-lucid1",:user=>"ubuntu",:uses_metadata => false},
            {:id=>"wmi-lucid5",:user=>"ubuntu",:uses_metadata => true},
            {:id=>"wmi-lucid6",:user=>"ubuntu",:uses_metadata => true}
          ],
          # The instance specs to test these images with
          :specs => ["is-demospec"],
          # The name of the ssh key to use with these images
          :ssh_key_id => ["ssh-demo"],
         },

        # Spec that tests if instances run properly with arguments
        :instance_spec => {
          # arguments to test spec with
          :image_id => "wmi-lucid0",
          :instance_spec_id => "is-demospec",
          :ssh_key_id => "ssh-demo",
          :hostname => "jefke",
          :security_groups => ["sg-demofgr"],
          :username => "ubuntu"
        },

        # Spec that tests the images api and cli
        :images_api_spec => {
          # The image to test with
          #:image_ids => ["wmi-lucid0","wmi-lucid1","wmi-lucid5","wmi-lucid6"],
          :local_image_ids    => ["wmi-lucid0", "wmi-lucid5"],
          :snapshot_image_ids => ["wmi-lucid1", "wmi-lucid6"]
        },

        # Spec that tests the host pools api
        :host_nodes_api_spec => {
          # The host pool to test with
          :host_node_ids => ["hn-demo1"]
        },

        # Spec that tests the instance specs api
        :instance_specs_api_spec => {
          :instance_spec_ids => ["is-demospec"]
        },

        # Spec that tests the networks web api
        :network_api_spec => {
          :network_ids => ["nw-demo1","nw-demo2","nw-demo3","nw-demo4","nw-demo5"]
        },

        # Spec that tests the ssh keys web api
        :ssh_key_pairs_api_spec => {
          :name => "testkey"
        },

        # Spec that tests the host pools web api
        :storage_nodes_api_spec => {
          :storage_ids => ["sn-demo1"]
        },

        # Spec that tests the volume snapshots web api
        :volume_api_spec => {
          :minimum_volume_size => 10,
          :maximum_volume_size => 3000,
          :test_volume_size => 99,
          # Snapshot id to try and create a volume from
          :snapshot_id => "snap-lucid1"
        },

        # Spec that tests the netfilter CRUD api
        :netfilter_group_api_apec => {
          :groups_to_create => [
            {:name => 'group1', :description => 'g1', :rule => "tcp:22,22,ip4:0.0.0.0"},
            {:name => 'group2', :description => 'g2', :rule => "icmp:-1,-1,a-00000000:g1\ntcp:22,22,a-00000000:g1"},
            {:name => 'group3', :description => 'g3', :rule => "icmp:-1,-1,a-00000000:g2\ntcp:22,22,a-00000000:g2"}
          ],
          :update_rule => "icmp:-1,-1,ip4:0.0.0.0"
        },

        # Spec that tests instances with multiple vnics
        :multiple_vnic_spec => {
          :images     => ['wmi-lucid0'],
          :specs      => ['is-demo2'],
          :schedulers => ['vif3type1','vif3type2']
        },
        # Spec that quickly tests several functions without going in detail
        :oneshot => {
          :sg_rule     =>  "tcp:22,22,ip4:0.0.0.0/24",
          :new_sg_rules => ["tcp:80,80,ip4:0.0.0.0","icmp:-1,-1,ip4:0.0.0.0"],
          :image_id    => 'wmi-lucid6',
          :spec_id     => 'is-demospec',
          :volume_size => 10,
          :user_name   => 'ubuntu'
        }
      }
    end

    # Returns a configuration read from an yaml file
    def config_from_yaml_file(path)

    end
  end
end

class APITest
  include HTTParty
  include Config
  cfg = Config::ConfigFactory.create_config

  base_uri cfg[:global][:api]
  #format :json
#  headers 'X-VDC-ACCOUNT-UUID' => 'a-00000000'
  #headers 'X-VDC-ACCOUNT-UUID' => 'a-shpoolxx'
  headers 'X-VDC-ACCOUNT-UUID' => cfg[:global][:account]

  def self.create(path, params)
    self.post(path, :query=>params, :body=>'')
  end

  def self.update(path, params)
    self.put(path, :query=>params, :body=>'')
  end
end

module RetryHelper
  include Config

  DEFAULT_WAIT_PERIOD=60*Config::ConfigFactory.create_config[:global][:retry_time]

  def retry_until(wait_sec=DEFAULT_WAIT_PERIOD, &blk)
    start_at = Time.now
    lcount=0
    loop {
      if blk.call
        break
      else
        sleep 2
      end
      lcount += 1
      raise("Retry Failure: Exceed #{wait_sec} sec: Retried #{count} times") if (Time.now - start_at) > wait_sec
    }
  end

  def retry_while(wait_sec=DEFAULT_WAIT_PERIOD, &blk)
    retry_until(wait_sec) do
      !blk.call
    end
  end
end

module InstanceHelper
  include RetryHelper

  def retry_until_running(instance_id)
    retry_until do
      case APITest.get("/instances/#{instance_id}")["state"]
      when 'running'
        true
      when 'terminated'
        raise "Instance terminated by the system due to booting failure."
      else
        false
      end
    end
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

  def retry_until_terminated(instance_id)
    retry_until do
      case APITest.get("/instances/#{instance_id}")["state"]
      when 'terminated'
        true
      else
        false
      end
    end
  end

  def retry_until_network_started(instance_id)
    retry_until do
      ping(instance_id).exitstatus == 0
    end
  end

  def retry_until_network_stopped(instance_id)
    retry_until do
      ping(instance_id).exitstatus != 0
    end
  end

  def ping(instance_id)
    ipaddr = APITest.get("/instances/#{instance_id}")["vif"].first["ipv4"]["address"]
    `ping -c 1 -W 1 #{ipaddr}`
    $?
  end

  def open_port?(instance_id, protocol, port)
    ipaddr = APITest.get("/instances/#{instance_id}")["vif"].first["ipv4"]["address"]
    case protocol
    when :tcp
      `echo | nc    #{ipaddr} #{port}`
    when :udp
      `echo | nc -u #{ipaddr} #{port}`
    else
      raise "Unknown protocol"
    end
    $?
  end

  def ssh_command(instance_id, user, command, do_retry)
    res = APITest.get("/instances/#{instance_id}")

    ssh_key_id = res["ssh_key_pair"]
    key_pair = APITest.get("/ssh_key_pairs/#{ssh_key_id}")

    suffix = Time.now.strftime("%s")
    private_key_path = "/tmp/vdc_id_rsa.pem.#{suffix}"
    open(private_key_path, "w") { |f| f.write(key_pair["private_key"]) }
    File.chmod(0600, private_key_path)
    sleep 5

    cmd = "ssh -o 'StrictHostKeyChecking no' -i #{private_key_path} #{user}@#{res["vif"].first["ipv4"]["address"]} '#{command}'"

    if do_retry
      retry_until do
        `#{cmd}`
        $?.exitstatus == 0
      end
    else
      `#{cmd}`
    end

    FileUtils.rm(private_key_path)
    $?
  end

  def retry_until_ssh_started(instance_id)
    ipaddr = APITest.get("/instances/#{instance_id}")["vif"].first["ipv4"]["address"]
    retry_until do
      `echo | nc #{ipaddr} 22`
      $?.exitstatus == 0
    end
  end

  def retry_until_loggedin(instance_id, user)
    ssh_command(instance_id, user, "hostname; whoami;", :retry)
  end

end

module NetfilterHelper

  def add_rules(netfilter_group_id, rules)
    new_rules = pickup_rules(get_rules(netfilter_group_id)) + rules
    update_rules(netfilter_group_id, new_rules)
  end

  def del_rules(netfilter_group_id, rules)
    new_rules = pickup_rules(get_rules(netfilter_group_id)) - rules
    update_rules(netfilter_group_id, new_rules)
  end

  def update_rules(netfilter_group_id, rules)
    APITest.update("/security_groups/#{netfilter_group_id}", {:rule => rules.uniq.join("\n")})
  end

  def get_rules(netfilter_group_id)
    APITest.get("/security_groups/#{netfilter_group_id}")
  end

  def pickup_rules(response)
    response["rules"].map { |cur| cur["permission"] }
  end

end

module CliHelper
  def init_env
    ENV["BUNDLE_GEMFILE"]  = nil
    ENV["BUNDLE_BIN_PATH"] = nil
    ENV["RUBYOPT"]         = nil
    ENV["GEM_HOME"]        = nil
  end

  def cd_gui_dir
    prefix_dir = File.dirname(File.expand_path('../../', __FILE__))
    Dir.chdir "#{prefix_dir}/frontend/dcmgr_gui"
  end

  def cd_dcmgr_dir
    prefix_dir = File.dirname(File.expand_path('../../', __FILE__))
    Dir.chdir "#{prefix_dir}/dcmgr"
  end
end

module VolumeHelper
  def attach_volume_to_instance(instance_id,volume_id)
    res = APITest.update("/volumes/#{volume_id}/attach", {:instance_id=>instance_id, :volume_id=>volume_id})
    res.success?.should be_true
    retry_until do
      # "available" -> "attaching" -> "attached"
      APITest.get("/volumes/#{volume_id}")["state"] == "attached"
    end
  end

  def detach_volume_from_instance(instance_id,volume_id)
    res = APITest.update("/volumes/#{volume_id}/detach", {:instance_id=>instance_id, :volume_id=>volume_id})
    res.success?.should be_true
    retry_until do
      # "attached" -> "detaching" -> "available"
      APITest.get("/volumes/#{volume_id}")["state"] == "available"
    end
  end

  def delete_volume(volume_id)
    APITest.delete("/volumes/#{volume_id}").success?.should be_true
    # "available" -> "deregistering" -> "deleted"
    retry_until do
      APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
    end
  end
end
