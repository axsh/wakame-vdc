# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/openvz_config.rb'

module Dcmgr
  module Drivers
    class OpenvzLocalStore < LinuxLocalStore
      include Dcmgr::Logger

      def upload_image(inst, ctx, bo, evcb)
        ctx = Openvz::OvzContext.new(ctx)
        case inst[:state]
          when 'halted'
            super
          else
            raise "Unsupported instance state: #{inst[:state]}"
        end
      end


      protected

      def vmimg_cache_dir
        OpenvzConfig.new.template_cache
      end
    end
  end
end
