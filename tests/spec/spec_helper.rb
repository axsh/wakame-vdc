
require 'rubygems'
require 'bundler/setup' rescue nil
require 'httparty'
require 'json'

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
