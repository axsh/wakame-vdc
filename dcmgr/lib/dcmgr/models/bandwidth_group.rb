# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Per account quota limit for the VDC resources.
  class BandwidthGroup < BaseNew
    taggable 'bg'
    
    TYPE_USER = 'user' #a user created bandwidth group that will likely have multiple vnics in it and exists until explicitely deleted.
    TYPE_AUTO = 'auto' #a bandwidth group automatically created to go with a vnic. Will be deleted along with the vnic that created it.
    
    TYPES = [TYPE_USER, TYPE_AUTO]
    
    inheritable_schema do
      Fixnum :account_id, :null=>false
      Float  :bandwidth, :null=>false #in Mbit/s
      String :type, :null=>false

      index :account_id
    end
    with_timestamps
    
    one_to_many :instance_nic

    def validate
      errors.add(:type, "Invalid type: #{self.type}") unless TYPES.member?(self.type)
    end

  end
end

