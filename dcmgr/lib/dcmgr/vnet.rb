# -*- coding: utf-8 -*-

module Dcmgr::VNet

  def self.packetfilter_service
    case Dcmgr.conf.sg_implementation
    when "netfilter"
      Netfilter::NetfilterAgent.new
    when "off"
      # Return the abstract class so no code is executed
      PacketfilterAgent.new
    end
  end

  module NetworkModes
    include Dcmgr::Logger
    include Dcmgr::Constants::Network

    class NetworkModeNotFoundError < StandardError
    end

    def self.get_mode(mode_name)
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
        raise NetworkModeNotFoundError, "Network mode #{mode_name} doesn't exist. Valid network modes: #{NETWORK_MODES.join(',')}"
      end
    end
  end

end
