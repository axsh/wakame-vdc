# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    # Set the dynamic config name method. For example:
    # loading hva.conf will create Dcmgr::Configurations.hva method
    def self.create_conf_methods(name, conf)
      @conf ||= Hash.new { |hash, key| raise "'#{key}' was not loaded." }
      @conf[name] = conf

      metaclass = class << self; self; end
      metaclass.instance_eval do
        define_method(name) { conf }
      end

      # Required for the deprecated Dcmgr.conf syntax
      @conf[:last] = conf
    end

    def self.load(conf_class, files)
      path = files.find { |i| File.exists?(i) }
      abort("ERROR: Failed to load #{files.inspect}.") if path.nil?

      begin
        conf_name = conf_class.name.split("::").last.downcase

        create_conf_methods(conf_name, conf_class.load(path))
      rescue NoMethodError => e
        abort("Syntax Error: #{path}\n  #{e.backtrace.first} #{e.message}")
      rescue Fuguta::Configuration::ValidationError => e
        abort("Validation Error: #{path}\n  " +
              e.errors.join("\n  ")
              )
      end
    end

    def self.loaded?
      ! @conf.nil?
    end

    # This method's only here to support the deprecated Dcmgr.conf method
    def self.last
      @conf && @conf[:last]
    end
  end
end

