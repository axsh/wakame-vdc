
require 'rubygems'
require 'bundler/setup' rescue nil
require 'httparty'
require 'json'

class APITest
  include HTTParty
  base_uri 'http://localhost:9001/api'
  #format :json
  headers 'X-VDC-ACCOUNT-UUID' => 'a-00000000'
  

  def self.create(path, params)
    self.post(path, :query=>params, :body=>'')
  end
end
