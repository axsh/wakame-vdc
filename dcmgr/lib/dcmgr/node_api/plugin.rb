# -*- coding: utf-8 -*-

module Dcmgr::NodeApi
  module Plugins
    def self.register(plugin)
      ::Dcmgr::NodeApi::Core::Base.plugins << plugin
    end
  end
end
