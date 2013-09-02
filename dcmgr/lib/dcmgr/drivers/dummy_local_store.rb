# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class DummyLocalStore < LocalStore
      def deploy_volume(hva_ctx, volume, backup_object, opts={})
      end

      def deploy_blank_volume(hva_ctx, volume, opts={})
      end
      
      def delete_volume(hva_ctx, volume)
      end
      
      def deploy_image(inst,ctx)
      end

      def upload_image(inst, ctx, bo, ev_callback)
      end
    end
  end
end
