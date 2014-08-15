# -*- coding: utf-8 -*-

module Dcmgr::NodeApi::Core
  class Base
    @plugins = []

    class << self
      attr_accessor :plugins
    end

    def run_hooks(timing, method_name)
      Dcmgr::NodeApi::Core::Base.plugins.each do |plugin|
        plugin_class = plugin.const_get("#{self.class.name.split("::").last}")
        plugin_class.send("#{timing}_#{method_name}")
      end
    end

    def self.inherited(klass)
      klass.instance_eval do
        @@method_names = [:create, :destroy, :update]

        def self.method_added(method_name)
          if @@method_names.member?(method_name)
            @@method_names.delete(method_name)

            alias_method "_#{method_name}".to_sym, method_name

            define_method(method_name) do |params|
              run_hooks(:before, method_name)
              send("_#{method_name}", params)
              run_hooks(:after, method_name)
            end
          end
        end
      end
    end
  end
end

Dir["#{Dcmgr::DCMGR_ROOT}/lib/dcmgr/node_api/plugins/*.rb"].each {|f| require f }
