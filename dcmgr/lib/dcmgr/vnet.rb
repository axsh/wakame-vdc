# -*- coding: utf-8 -*-

module Dcmgr::VNet

  def self.packetfilter_service
    case Dcmgr.conf.edge_networking
    when "netfilter"
      Netfilter::NetfilterAgent.new
    when "off"
      Class.new {
        def init_security_group(*args); end
        def destroy_security_group(*args); end
        def update_isolation_group(*args); end
        def init_vnic_on_host(*args); end
        def destroy_vnic_on_host(*args); end
        def set_vnic_security_groups(*args); end
        def handle_referencees(*args); end
        def refresh_referencers(*args); end
        def update_secg_rules(*args); end
        def commit_changes(*args); {}; end
      }.new
    end
  end

  module NetworkModes
    include Dcmgr::Logger
    include Dcmgr::Constants::Network

    class NetworkModeNotFoundError < StandardError
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
        raise NetworkModeNotFoundError, "Network mode #{mode_name} doesn't exist. Valid network modes: #{NETWORK_MODES.join(',')}"
      end
    end
  end

end
