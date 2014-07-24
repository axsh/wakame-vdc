# -*- coding: utf-8 -*-

require "fuguta"

module Dcmgr
  module Configurations
    class Hma < Fuguta::Configuration
      param :monitor_frequency_sec, :default=>10
      param :monitor_script_path, :default=>nil
      
      def validate(errors)
        if !@config[:monitor_script_path].nil? &&
            !File.executable?(@config[:monitor_script_path].to_s)
          errors << "Invalid executable path for monitor_script_path: #{@config[:monitor_script_path]}"
        end

        @config[:monitor_frequency_sec] = @config[:monitor_frequency_sec].to_i
        if @config[:monitor_frequency_sec].to_i < 1
          errors << "monitor_frequency_sec must be more than 0: #{@config[:monitor_frequency_sec]}"
        end
      end

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
