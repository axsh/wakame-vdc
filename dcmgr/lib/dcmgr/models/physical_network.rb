# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Physical network interface
  class PhysicalNetwork < BaseNew

    one_to_many :network

    def validate
      super
    end

    def before_destroy
      super
    end

  end
end
