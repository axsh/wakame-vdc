# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    module ClassMethods
      # Set the dynamic config name method. For example:
      # loading hva.conf will create Dcmgr::Configurations.hva method
      def store_conf(name, conf)
        @conf ||= Hash.new { |hash, key| raise "'#{key}' was not loaded." }
        @conf[name.to_sym] = conf

        # Required for the deprecated Dcmgr.conf syntax
        @conf[:last] = conf
      end

      def load(conf_class, files = nil)
        path = if files
                 abort("ERROR: files must be a 'Array'. Got '#{files.class}'") unless files.is_a?(Array)
                 path = files.find { |i| File.exists?(i) }
                 abort("ERROR: Failed to load #{files.inspect}.") if path.nil?

                 path
               end

        begin
          conf_name = conf_class.name.split("::").last.downcase

          store_conf(conf_name, conf_class.load(path))
        rescue NoMethodError => e
          abort("Syntax Error: #{path}\n  #{e.backtrace.first} #{e.message}")
        rescue Fuguta::Configuration::ValidationError => e
          abort("Validation Error: #{path}\n  " +
                e.errors.join("\n  ")
                )
        end
      end

      def loaded?(name = nil)
        if name.nil?
          ! @conf.nil?
        else
          @conf.has_key?(name.to_sym)
        end
      end

      # This method's only here to support the deprecated Dcmgr.conf method
      def last
        @conf && @conf[:last]
      end

      # This allows us to access the configurations as if they're methods of
      # Dcmgr::Configurations.
      # For example: Dcmgr::Configurations.dcmgr will access dcmgr.conf
      def method_missing(method_name, *args)
        @conf[method_name]
      end
    end

    extend ClassMethods
  end
end

