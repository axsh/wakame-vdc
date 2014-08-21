# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:test)

$LOAD_PATH << File.expand_path("./helpers", File.dirname(__FILE__))
require 'vdc_vnet_spec'

def self.feature(*args, &blk)
  describe(*args, &blk)
end

class << RSpec::Core::ExampleGroup
  def scenario(*args, &blk)
    it(*args, &blk)
  end
end

RSpec.configure do |c|
  c.formatter = :documentation
  c.color     = true
end
