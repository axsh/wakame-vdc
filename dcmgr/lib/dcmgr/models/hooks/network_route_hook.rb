# -*- coding: utf-8 -*-

module Dcmgr
  module Models
    class NetworkRoute
      after_create do |network_route|
        network_route.db.after_commit do
          ::Dcmgr.messaging.event_publish("vnet/network_route/created", :args=>[network_route.id])
          true
        end
      end
      after_destroy do |network_route|
        network_route.db.after_commit do
          ::Dcmgr.messaging.event_publish("vnet/network_route/deleted", :args =>[network_route.id])
          true
        end
      end
    end
  end
end
