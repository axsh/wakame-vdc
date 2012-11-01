# -*- coding: utf-8 -*-

module Dcmgr::Constants::Network
  # securitygroup: security grouped network.
  NM_SECURITYGROUP="securitygroup".freeze
  # passthrough: do not apply any modifications to the packets from VM.
  NM_PASSTHROUGH="passthrough".freeze
  # l2overlay: L2 overlay private network. (L2 over IP)
  NM_L2OVERLAY="l2overlay".freeze

  NETWORK_MODES=[NM_PASSTHROUGH,NM_SECURITYGROUP,NM_L2OVERLAY].freeze
end
