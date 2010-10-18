# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetfilterRule < BaseNew
    with_timestamps

    inheritable_schema do
      Fixnum :netfilter_group_id, :null=>false
      String :permission, :null=>false
    end

    many_to_one :netfilter_group

  end
end
