# -*- coding: utf-8 -*-
require 'fuguta'

module Dcmgr
  module Drivers
    class IscsiTarget < StorageTarget
      attr_reader :node

      def_configuration do
        param :iqn_prefix, :default=>'iqn.2010-09.jp.wakame'
      end

      # Register target information to the target device.
      # @param [Hash] volume hash data
      def register(volume)
        # TODO: uncomment here once all drivers were updated.
        #raise NotImplmenetedError
      end
    end
  end
end
