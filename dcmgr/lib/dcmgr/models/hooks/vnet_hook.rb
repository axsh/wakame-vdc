# -*- coding: utf-8 -*-

def filter_params(name, vdc_params, filter)
  vnet_params = {}
  filter.each do |vnet, vdc|
    vnet_params[vnet] = case vdc
                        when Symbol then vdc_params[vdc]
                        else vdc
                        end
  end
  DCell::Node['vnmgr']['vdc_vnet_plugin'] && DCell::Node['vnmgr']['vdc_vnet_plugin'].async.create_entry(name, vnet_params)
  true
end

Dcmgr::Models::Network.after_create do |network|
  filter_params(:Network, network.to_hash, {
    :uuid => :uuid,
    :display_name => :display_name,
    :ipv4_network => :ipv4_network,
    :ipv4_prefix => :prefix,
    :domain_name => :domain_name,
    :network_mode => 'virtual',
    :editable => :editable
  })
end

Dcmgr::Models::NetworkVif.after_create do |nvif|
  unless nvif.instance_id.nil?
    filter_params(:NetworkVif, nvif.to_hash, {
      :uuid => "if-#{nvif.uuid}",
      :port_name => "if-#{nvif.uuid}",
      :mac_address => nvif && nvif.pretty_mac_addr
    })
  end
end

Dcmgr::Models::NetworkVifIpLease.after_create do |nvil|
  unless nvil.network_vif_id.nil?
    filter_params(:NetworkVifIpLease, nvil.to_hash, {
      :network_uuid => nvil.network && nvil.network.canonical_uuid,
      :interface_uuid => nvil.network_vif && "if-#{nvil.network_vif.uuid}",
      :ipv4_address => nvil && nvil.ipv4_s
    })
  end
end

Dcmgr::Models::NetworkService.after_create do |network_service|
  filter_params(:NetworkService, network_service.to_hash, {
    :name => :name,
    :ipv4_address => :address,
    :mac_address => :mac_addr,
    :network_uuid => network_service.network_vif.network.canonical_uuid
  })
end



