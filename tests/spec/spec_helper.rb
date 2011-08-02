
require 'rubygems'
require 'bundler/setup' rescue nil
require 'httparty'
require 'json'

require 'rspec'

class APITest
  include HTTParty
  base_uri 'http://localhost:9001/api'
  #format :json
  headers 'X-VDC-ACCOUNT-UUID' => 'a-00000000'
  

  def self.create(path, params)
    self.post(path, :query=>params, :body=>'')
  end
end

module RetryHelper
  def retry_until(count=10, &blk)
    lcount = 0
    count.times { |n|
      if blk.call
        break
      else
        sleep 2
      end
      lcount = n
    }
    count <= lcount && abort("All retry failed within #{count*2} sec")
  end

  def retry_while(count=10, &blk)
    retry_while do
      !blk.call
    end
  end
end
