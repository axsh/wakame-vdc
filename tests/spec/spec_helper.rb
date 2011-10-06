
require 'rubygems'
require 'bundler/setup' rescue nil
require 'httparty'
require 'json'
require 'fileutils'

require 'rspec'

class APITest
  include HTTParty
  base_uri 'http://localhost:9001/api'
  #format :json
#  headers 'X-VDC-ACCOUNT-UUID' => 'a-00000000'
  headers 'X-VDC-ACCOUNT-UUID' => 'a-shpoolxx'

  def self.create(path, params)
    self.post(path, :query=>params, :body=>'')
  end

  def self.update(path, params)
    self.put(path, :query=>params, :body=>'')
  end
end

module RetryHelper
  DEFAULT_WAIT_PERIOD=60*30 # 30mins
  
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
    ipaddr = APITest.get("/instances/#{instance_id}")["vif"].first["ipv4"]["address"]
    retry_until do
      `ping -c 1 -W 1 #{ipaddr}`
      $?.exitstatus == 0
    end
  end

  def ping(instance_id)
    ipaddr = APITest.get("/instances/#{instance_id}")["vif"].first["ipv4"]["address"]
    `ping -c 1 -W 1 #{ipaddr}`
    $?
  end

  def open_port(instance_id, protocol, port)
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

    key_pair = APITest.get("/ssh_key_pairs").first["results"].map { |key_pair|
      key_pair if key_pair["name"] == res["ssh_key_pair"]
    }.first

    suffix = Time.now.strftime("%s")
    private_key_path = "/tmp/vdc_id_rsa.pem.#{suffix}"
    open(private_key_path, "w") { |f| f.write(key_pair["private_key"]) }
    File.chmod(0600, private_key_path)

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

  def retrieve_netfilter_by_name(netfilter_group_name)
    APITest.get("/netfilter_groups").first["results"].map { |netfilter|
      netfilter if netfilter["name"] == netfilter_group_name
    }.first
  end

  def add_rules(netfilter_group_id, rules)
    new_rules = pickup_rules(get_rules(netfilter_group_id)) + rules
    update_rules(netfilter_group_id, new_rules)
  end

  def del_rules(netfilter_group_id, rules)
    new_rules = pickup_rules(get_rules(netfilter_group_id)) - rules
    update_rules(netfilter_group_id, new_rules)
  end

  def update_rules(netfilter_group_id, rules)
    APITest.update("/netfilter_groups/#{netfilter_group_id}", {:rule => rules.uniq.join("\n")})
  end

  def get_rules(netfilter_group_id)
    APITest.get("/netfilter_groups/#{netfilter_group_id}")
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
