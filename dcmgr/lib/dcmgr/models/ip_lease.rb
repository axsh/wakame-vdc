# -*- coding: utf-8 -*-

module Dcmgr::Models
  # IP address lease information
  class IpLease < BaseNew

    inheritable_schema do
      Fixnum :instance_nic_id, :null=>false
      Fixnum :network_id, :null=>false
      String :ipv4
      
      index :ipv4, {:unique=>true}
    end
    with_timestamps

    many_to_one :instance_nic
    one_to_one :network
  end
end
