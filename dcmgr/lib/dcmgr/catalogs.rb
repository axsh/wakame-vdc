# -*- coding: utf-8 -*-

require 'yaml'

module Dcmgr
  module Catalogs
    extend Configurations::ClassMethods

    class CatalogBase
      def initialize
        @config = {}
      end

      def self.usual_paths(paths = nil)
        if paths
          @usual_paths = paths
        else
          @usual_paths
        end
      end

      def usual_paths
        self.class.usual_paths
      end

      def self.load(*paths)
        c = self.new
        l = Loader.new(c)

        if paths.empty?
          l.load
        else
          paths.each { |path| l.load(path) }
        end
        c
      end

      def find(key)
        if @config.has_key?(key.to_i)
          @config[key.to_i]
        elsif @config.has_key?(key.to_s)
          @config[key.to_s]
        end
      end

      def find_all
        @config
      end

      def method_missing(m, *args)
        if @config.has_key?(m.to_s)
          @config[m.to_s]
        else
          super
        end
      end

      class Loader
        def initialize(catalog)
          @catalog = catalog
        end

        def load(path = nil)
          buf = case path
                when NilClass
                  raise "No path given usual_paths not set" unless @catalog.usual_paths

                  path = @catalog.usual_paths.find { |path| File.exists?(path) } ||
                    raise("None of the usual_paths existed: #{@catalog.usual_paths.join(", ")}")

                  YAML.load_file(path)
                when String
                  raise "does not exist: #{path}" unless File.exists?(path)
                  YAML.load_file(path)
                else
                  raise "Unknown Type: #{path.class}"
                end

          @catalog.instance_variable_set(:@config, buf)
        end
      end
    end

    class LoadBalancer < CatalogBase
      usual_paths [
                   ENV['CATALOG_PATH'].to_s,
                   '/etc/wakame-vdc/catalogs/load_balancer.yml',
                   '/etc/wakame-vdc/convert_specs/load_balancer.yml',
                   File.expand_path('config/catalogs/load_balancer.yml', ::Dcmgr::DCMGR_ROOT),
                   File.expand_path('config/convert_specs/load_balancer.yml', ::Dcmgr::DCMGR_ROOT)
                  ]

    end

    class VirtualDataCenter < CatalogBase
      usual_paths [
                   ENV['CATALOG_PATH'].to_s,
                   '/etc/wakame-vdc/catalogs/virtual_data_center.yml',
                   File.expand_path('config/catalogs/virtual_data_center.yml', ::Dcmgr::DCMGR_ROOT)
                  ]
    end
  end
end
