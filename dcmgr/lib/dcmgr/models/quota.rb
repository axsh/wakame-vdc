# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Per account quota limit for the VDC resources.
  class Quota < BaseNew
    inheritable_schema do
      Fixnum :account_id, :null=>false
      Float  :instance_total_weight
      Fixnum :volume_total_size

      index :account_id
    end
    with_timestamps

    def before_validation
      # sets default quota values from dcmgr.conf.
      self.instance_total_weight ||= Dcmgr.conf.account_instance_total_weight
      self.volume_total_size ||= Dcmgr.conf.account_volume_total_size
      super
    end
  end
end

