# -*- coding: utf-8 -*-

require "fuguta"
require 'dcmgr/node_modules/ha_manager'

module Dcmgr
  module Configurations
    class Hma < Fuguta::Configuration

      usual_paths [
        ENV['CONF_PATH'].to_s,
        '/etc/wakame-vdc/hma.conf',
        File.expand_path('config/hma.conf', ::Dcmgr::DCMGR_ROOT)
      ]


      class MonitorTarget < Fuguta::Configuration
        def after_initialize
          @config[:monitor_items] = {}
        end

        DSL do
          def monitor_item(name, klass_sym, &blk)
            if @config[:monitor_items].has_key?(name)
              raise "monitor item name '#{name}' is duplicated."
            end
            monitor_item_class = ::Dcmgr::NodeModules::HaManager::MonitorItem.const_get(klass_sym, false)
            # each MonitorItem class has Configuration constant.
            begin
              conf_class = monitor_item_class.const_get(:Configuration, false)
            rescue NameError => e
              raise "#{monitor_item_class} is missing configuration class."
            end
            mi = monitor_item_class.new(conf_class.new(@subject).parse_dsl(&blk))
            @config[:monitor_items][name] = mi
          end

          def conditions(&blk)
            @config[:conditions] = blk
          end
        end
      end

      DSL do
        def monitor_target(&blk)
          @config[:monitor_target].parse_dsl(&blk)
        end
      end

      def after_initialize
        @config[:monitor_target] = MonitorTarget.new(self)
      end

      # For backward compatiblity.
      def instance_ha
        self
      end
    end
  end
end
