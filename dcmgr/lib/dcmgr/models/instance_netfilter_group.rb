# -*- coding: utf-8 -*-

module Dcmgr::Models
  class InstanceNetfilterGroup < BaseNew

    inheritable_schema do
      Fixnum :instance_id, :null=>false
      Fixnum :netfilter_group_id, :null=>false
    end
#    with_timestamps

    many_to_one :instance
    many_to_one :netfilter_group
  end

end
