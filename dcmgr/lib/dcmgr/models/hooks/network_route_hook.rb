# -*- coding: utf-8 -*-

Dcmgr::Models::NetworkRoute.after_create do |network_route|
  network_route.db.after_commit do
    Dcmgr.messaging.event_publish("vnet/network_route/created", :args=>[network_route.id])
  end
  true
end

Dcmgr::Models::NetworkRoute.after_destroy do |network_route|
  network_route.db.after_commit do
    Dcmgr.messaging.event_publish("vnet/network_route/deleted", :args =>[network_route.id])
  end
  true
end
