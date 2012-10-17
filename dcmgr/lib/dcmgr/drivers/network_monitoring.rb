# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class NetworkMonitoring
    def register_instance(instance)
    end

    def unregister_instance(instance)
    end

    def self.driver_class(key)
      case key.to_s
      when 'zabbix'
        Zabbix
      else
        raise "Unknown network monitoring driver: #{key}"
      end
    end
  end
end
