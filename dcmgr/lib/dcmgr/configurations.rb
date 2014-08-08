# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations

    module Shorthand
      # This module is used to define shorthand access to configuration methods.
      # Once dcmgr.conf is loaded, you can access it this way:
      #
      # include Dcmgr::Configurations::Shorthand
      #
      # dcmgr_conf
      #
      # ie. dcmgr_conf.db_uri == Dcmgr::Configurations.dcmgr.db_uri

      def load_conf(conf_class, files = nil)
        ::Dcmgr::Configurations.load(conf_class, files)
      end
    end

    def self.create_shorthand(name, conf)
      @conf ||= Hash.new { |hash, key| raise "'#{key}' was not loaded." }
      @conf[name.to_sym] = conf

      Shorthand.instance_eval do
        define_method("#{name}_conf") { conf }
      end

      # Required for the deprecated Dcmgr.conf syntax
      @conf[:last] = conf
    end

    # This allows us to access the configurations as if they're methods of
    # Dcmgr::Configurations.
    # For example: Dcmgr::Configurations.dcmgr will access dcmgr.conf
    def self.method_missing(method_name, *args)
      @conf[method_name]
    end

    def self.load(conf_class, files = nil)
      path = if files
        path = files.find { |i| File.exists?(i) }
        abort("ERROR: Failed to load #{files.inspect}.") if path.nil?

        path
      end

      begin
        conf_name = conf_class.name.split("::").last.downcase

        create_shorthand(conf_name, conf_class.load(path))
      rescue NoMethodError => e
        abort("Syntax Error: #{path}\n  #{e.backtrace.first} #{e.message}")
      rescue Fuguta::Configuration::ValidationError => e
        abort("Validation Error: #{path}\n  " +
              e.errors.join("\n  ")
              )
      end
    end

    def self.loaded?(name = nil)
      if name.nil?
        ! @conf.nil?
      else
        @conf.has_key?(name.to_sym)
      end
    end

    # This method's only here to support the deprecated Dcmgr.conf method
    def self.last
      @conf && @conf[:last]
    end
  end
end

