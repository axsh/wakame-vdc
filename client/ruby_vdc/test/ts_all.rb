# -*- coding: utf-8 -*-

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'ruby_vdc'

ActiveResource::Base.class_eval do 
  self.site = 'http://localhost:9001'
end

ActiveResource::Connection.set_vdc_account_uuid('a-shpoolxx')

['api'].each do |l|
  Dir.glob(File.join(File.dirname(__FILE__) + "/#{l}", '*.rb')).each do |f|
    require f
  end
end
