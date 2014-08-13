# -*- coding: utf-8 -*-

require "fuguta"

module Dcmgr
  module Configurations
    class Hma < Base

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
          def monitor_item(name, klass_sym, *args)
            monitor_item_class = ::Dcmgr::NodeModules::HaManager::MonitorItem.const_get(klass_sym)
            mi = monitor_item_class.new(*args)
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
