# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class DummyLocalStore < LocalStore
      def deploy_image(inst,ctx)
      end

      def upload_image(inst, ctx, bo, ev_callback)
      end
    end
  end
end
