# encoding: utf-8
require 'rubygems'
require 'httparty'

######################################
# Helper class
######################################
class APITest
  include HTTParty

  # HTTPParty uses Crack as JSON/XML parser but it did not work well
  # with response from ssh_key_pairs API. This uses the JSON parser instead.
  class UseJSONParser < HTTParty::Parser
    def json
      require 'json'
      JSON.parse(self.body)
    end
  end

  def self.api_ver(ver=nil)
    return default_options[:api_ver] unless ver
    base_uri(self.api_base_uri + '/' + ver) if self.api_base_uri
    default_options[:api_ver] = ver
  end

  # overwrite base_uri to append API version path.
  def self.api_base_uri(uri=nil)
    return default_options[:api_base_uri] unless uri
    base_uri(uri + '/' + self.api_ver) if self.api_ver
    default_options[:api_base_uri] = uri
  end

  api_ver ''
  api_base_uri "http://localhost:9001/api"

  parser UseJSONParser
  headers 'X-VDC-ACCOUNT-UUID' => 'a-shpoolxx'

  def self.create(path, params)
    self.post(path, :query=>params, :body=>'')
  end

  def self.update(path, params)
    self.put(path, :query=>params, :body=>'')
  end

  def self.send_action(call, path, params)
    case call
    when "put"
      self.put(path, :query => params, :body => '')
    when "post"
      self.post(path, :query => params, :body => '')
    else
      send(call, path, params)
    end
  end
end

module RetryHelper
  #include Config
  
  DEFAULT_WAIT_PERIOD=60*5
  
  def retry_while_not(wait_sec=DEFAULT_WAIT_PERIOD, &blk)
    start_at = Time.now
    lcount=0
    loop {
      if blk.call
        raise("Retry Failure: block returned true. Retried #{lcount} times")
      else
        sleep 2
      end
      lcount += 1
      break if (Time.now - start_at) > wait_sec
    }
  end
  
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
      raise("Retry Failure: Exceed #{wait_sec} sec: Retried #{lcount} times") if (Time.now - start_at) > wait_sec
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

  def ping(instance_id)
    ipaddr = APITest.get("/instances/#{instance_id}")["vif"].first["ipv4"]["address"]
    `ping -c 1 -W 1 #{ipaddr}`
    $?
  end

  def ssh_command(instance_id, user, command, seconds)
    res = APITest.get("/instances/#{instance_id}")

    ssh_key_id = res["ssh_key_pair"]
    key_pair = APITest.get("/ssh_key_pairs/#{ssh_key_id}")

    suffix = Time.now.strftime("%s")
    private_key_path = "/tmp/vdc_id_rsa.pem.#{suffix}"
    open(private_key_path, "w") { |f| f.write(key_pair["private_key"]) }
    File.chmod(0600, private_key_path)
    sleep 5

    cmd = "ssh -o 'StrictHostKeyChecking no' -i #{private_key_path} #{user}@#{res["vif"].first["ipv4"]["address"]} '#{command}'"

    output = ""
    if seconds > 0
      retry_until(seconds) do
        output = %x{#{cmd}}
        $?.exitstatus == 0
      end
    else
      output = %x{#{cmd}}
    end

    FileUtils.rm(private_key_path)
    output
  end

  def retry_until_loggedin(instance_id, user, seconds = 0)
    ssh_command(instance_id, user, "hostname; whoami;", seconds)
  end

end
