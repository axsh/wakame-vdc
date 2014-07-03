# -*- coding: utf-8 -*-

module Dcmgr::EdgeNetworking
  class PacketfilterService
    attr_reader :pending_changes

    def initialize
      flush_pending_changes
    end

    # pending_changes hash format:
    # {
    #   host_node => ["change_command1", "change_command2"],
    #   host_node => ["change_command3", "change_command4"]
    # }
    def flush_pending_changes
      @pending_changes = {}
    end

    def init_security_group(*args); end
    def destroy_security_group(*args); end
    def update_isolation_group(*args); end
    def init_vnic_on_host(*args); end
    def destroy_vnic_on_host(*args); end
    def set_vnic_security_groups(*args); end
    def handle_referencees(*args); end
    def refresh_referencers(*args); end
    def update_secg_rules(*args); end
  end
end
