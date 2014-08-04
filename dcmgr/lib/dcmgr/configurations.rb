# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    def self.load_conf(name, conf)
      metaclass = class << self; self; end

      @conf ||= Hash.new { |hash, key| raise "'#{key}' was not loaded." }

      @conf[name] = conf

      metaclass.instance_eval do
        define_method(name) { @conf[name] }
      end

      # Required for the deprecated Dcmgr.conf syntax
      @conf[:last] = conf
    end

    def self.last
      @conf && @conf[:last]
    end
  end
end

