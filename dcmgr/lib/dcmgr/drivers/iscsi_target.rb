# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class IscsiTarget

      def create(ctx)
      end

      def delete(ctx)
      end

      def self.select_iscsi_target(iscsi_target)
        case iscsi_target
        when "sun_iscsi"
          bs = Dcmgr::Drivers::SunIscsi.new
        when "comstar"
          bs = Dcmgr::Drivers::Comstar.new
        else
          raise "Unknown iscsi_target type: #{iscsi_target}"
        end
        bs
      end
    end
  end
end
