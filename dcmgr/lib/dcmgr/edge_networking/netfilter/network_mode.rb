# -*- coding: utf-8 -*-

module Dcmgr::EdgeNetworking::Netfilter

  module NetworkModes
    include Dcmgr::Logger
    include Dcmgr::Constants::Network

    class NetworkModeNotFoundError < StandardError; end

    class Base
      def init_vnic(vnic_map)
        raise NotImplementedError
      end

      def destroy_vnic(vnic_map)
        raise NotImplementedError
      end

      def set_vnic_security_groups(vnic_id, secg_ids)
        raise NotImplementedError
      end
    end

    def self.get_mode(mode_name, legacy = false)
      case mode_name
      when NM_SECURITYGROUP
        logger.debug "Selecting #{NM_SECURITYGROUP} network mode"
        SecurityGroup.new
      when NM_PASSTHROUGH
        logger.debug "Selecting #{NM_PASSTHROUGH} network mode"
        PassThrough.new
      when NM_L2OVERLAY
        logger.debug "Selecting #{NM_L2OVERLAY} network mode"
        L2Overlay.new
      else
        raise NetworkModeNotFoundError,
          "Network mode '%s' doesn't exist. Valid network modes: %s" %
          [mode_name, NETWORK_MODES.join(',')]
      end
    end
  end

end
