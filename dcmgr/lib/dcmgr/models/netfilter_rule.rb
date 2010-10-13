# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetfilterRule < BaseNew
    taggable 'nfrule'
    with_timestamps

    inheritable_schema do
      String :source, :null=>false
      String :permission, :null=>false
    end

    many_to_one :netfilter_group
  end
end
