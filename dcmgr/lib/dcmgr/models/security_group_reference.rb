# -*- coding: utf-8 -*-

module Dcmgr::Models
  class SecurityGroupReference < BaseNew

    many_to_one :recerenced_group
    many_to_one :referencing_group
  end
end
