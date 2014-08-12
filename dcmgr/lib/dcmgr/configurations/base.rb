# -*- coding: utf-8 -*-

module Dcmgr::Configurations
  class Base < Fuguta::Configuration
    # This method is used to define shorthand access to configuration methods.
    # Once dcmgr.conf is loaded, you can access it this way:
    #
    # === code ====
    # Dcmgr::Configurations::Dcmgr.include_helper(self)
    #
    # dcmgr_conf
    # === end code ===
    #
    # ie. dcmgr_conf.db_uri == Dcmgr::Configurations.dcmgr.db_uri
    def self.include_helper(klass)
      name = self.name.split("::").last.downcase

      klass.instance_eval do
        define_method("#{name}_conf") { ::Dcmgr::Configurations.send(name) }
      end
    end
  end
end
