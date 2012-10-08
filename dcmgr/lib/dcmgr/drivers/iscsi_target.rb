# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class IscsiTarget
      attr_reader :node

      def create(ctx)
        raise NotImplmenetedError
      end

      def delete(ctx)
        raise NotImplmenetedError
      end

      # Register target information to the target device.
      # @param [Hash] volume hash data
      def register(volume)
        # TODO: uncomment here once all drivers were updated.
        #raise NotImplmenetedError
      end

      def self.select_iscsi_target(iscsi_target, node)
        raise ArgumentError unless node.is_a?(Isono::Node)
        case iscsi_target
        when "linux_iscsi"
          bs = Dcmgr::Drivers::LinuxIscsi.new
        when "sun_iscsi"
          bs = Dcmgr::Drivers::SunIscsi.new
        when "comstar"
          bs = Dcmgr::Drivers::Comstar.new
	when "ifs_iscsi"
	  bs = Dcmgr::Drivers::IfsIscsi.new
        else
          raise "Unknown iscsi_target type: #{iscsi_target}"
        end
        # for bs.node readable accessor.
        bs.instance_variable_set(:@node, node)
        bs
      end
    end
  end
end
