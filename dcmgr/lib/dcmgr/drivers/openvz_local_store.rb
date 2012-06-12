# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/openvz_config.rb'

module Dcmgr
  module Drivers
    class OpenvzLocalStore < LinuxLocalStore
      include Dcmgr::Logger

      protected

      def vmimg_cache_dir
        File.expand_path("cache", OpenvzConfig.new.template)
      end
    end
  end
end
