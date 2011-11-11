# -*- coding: utf-8 -*-

module Dcmgr::Models
  class InstanceNetfilterGroup < BaseNew

    many_to_one :instance
    many_to_one :netfilter_group
  end
end
