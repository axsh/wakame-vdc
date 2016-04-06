# -*- coding: utf-8 -*-
module Dcmgr
  module Drivers
    class Nfs < StorageTarget
      attr_reader :node

      def create(ctx)
        # Nothing to do
      end

      def delete(ctx)
        # Nothing to do
      end
    end
  end
end
