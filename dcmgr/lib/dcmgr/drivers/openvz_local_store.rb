# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/openvz_config.rb'

module Dcmgr
  module Drivers
    class OpenvzLocalStore < LinuxLocalStore
      include Dcmgr::Logger

      def upload_image(inst, ctx, bo, evcb)
        ctx = Openvz::OvzContext.new(ctx)
        cgroup_context(:subsystem=>'blkio', :scope=>ctx.ctid) do
          super
        end
      end


      protected

      def vmimg_cache_dir
        OpenvzConfig.new.template_cache
      end
    end
  end
end
