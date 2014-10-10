# -*- coding: utf-8 -*-

def filter_params(name, vdc_params, filter)
  vnet_params = {}
  filter.each do |vnet, vdc|
    vnet_params[vnet] = case vdc
                        when Symbol then vdc_params[vdc]
                        else vdc
                        end
  end
  vnmgr = DCell::Node['vnmgr']['vdc_vnet_plugin']
  vnmgr && vnmgr.async.create_entry(name, vnet_params)
  true
end

def destroy_entry(class_name, uuid_or_id)
  vnmgr = DCell::Node['vnmgr']['vdc_vnet_plugin']
  vnmgr && vnmgr.async.destroy_entry(class_name, uuid_or_id)
end

Dcmgr::Models::Network.after_create do |network|
  filter_params(:Network, network.to_hash, {
    :uuid => :uuid,
    :display_name => :display_name,
    :ipv4_network => :ipv4_network,
    :ipv4_prefix => :prefix,
    :domain_name => :domain_name,
    :network_mode => 'virtual'
  })
end

Dcmgr::Models::Network.after_destroy do |network|
  destroy_entry(:Network, network.canonical_uuid)
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

Dcmgr::Models::NetworkVif.after_destroy do |nvif|
  destroy_entry(:NetworkVif, "if-#{nvif.uuid}")
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

Dcmgr::Models::NetworkVifIpLease.after_destroy do |network_vif_ip_lease|
  destroy_entry(
    :NetworkVifIpLease,
    :interface_uuid => "if-#{network_vif_ip_lease.network_vif.uuid}",
    :network_uuid => network_vif_ip_lease.network.canonical_uuid,
    :ipv4_address => network_vif_ip_lease.ipv4_i
  )
end

Dcmgr::Models::NetworkService.after_create do |network_service|
  filter_params(:NetworkService, network_service.to_hash, {
    :name => :name,
    :ipv4_address => :address,
    :mac_address => :mac_addr,
    :network_uuid => network_service.network_vif.network.canonical_uuid
  })
end

Dcmgr::Models::NetworkRoute.after_create do |network_route|
  outer_lease = Dcmgr::Models::NetworkVifIpLease[network_route.outer_lease_id]
  inner_lease = Dcmgr::Models::NetworkVifIpLease[network_route.inner_lease_id]

  filter_params(:NetworkRoute, network_route.to_hash, {
    :ingress_ipv4_address => outer_lease.ipv4_s,
    :egress_ipv4_address => inner_lease.ipv4_s,
    :outer_network_uuid => outer_lease.network.canonical_uuid,
    :inner_network_uuid => inner_lease.network.canonical_uuid,
    :outer_network_gw => outer_lease.network.ipv4_gw,
    :inner_network_gw => inner_lease.network.ipv4_gw
  })
end

Dcmgr::Models::NetworkService.after_destroy do |network_service|
  destroy_entry(:NetworkService, network_service.canonical_uuid)
end

Dcmgr::Models::SecurityGroup.after_create do |security_group|
  security_group.db.after_commit do
    converted_rule = (security_group.rule || "").split("\n").map do |rule|
      next rule if rule =~ /^ *#/

      #  Maybe more strict expression should be required
      m = rule.match(/^(?<protocol>[^:]*):(?<from_port>-?\d+),(?<to_port>-?\d+),ip4:(?<ipaddr>.+)$/)
      raise "Invalid rule. security_group: #{security_group.canonical_uuid} rule: #{rule}" unless m

      if m[:protocol] == "icmp"
        "#{m[:protocol]}::#{m[:ipaddr]}"
      elsif m[:from_port] != m[:to_port]
        (m[:from_port].to_i...m[:to_port].to_i).map do |port|
          "#{m[:protocol]}:#{port}:#{m[:ipaddr]}"
        end
      else
        "#{m[:protocol]}:#{m[:from_port]}:#{m[:ipaddr]}"
      end
    end.flatten.join("\n")

    filter_params(:SecurityGroup, security_group.to_hash, {
      :uuid => :uuid,
      :display_name => security_group.display_name || security_group.canonical_uuid,
      :rules => converted_rule,
      :description => :description
    })
  end
end

Dcmgr::Models::SecurityGroup.after_destroy do |security_group|
  destroy_entry(:SecurityGroup, security_group.canonical_uuid)
end

Dcmgr::Models::NetworkVifSecurityGroup.after_create do |network_vif_security_group|
  network_vif_security_group.db.after_commit do
    filter_params(:NetworkVifSecurityGroup, network_vif_security_group.to_hash, {
      :interface_uuid => "if-#{network_vif_security_group.network_vif.uuid}",
      :security_group_uuid => "sg-#{network_vif_security_group.security_group.uuid}"
    })
  end
end

Dcmgr::Models::NetworkVifSecurityGroup.after_destroy do |network_vif_security_group|
  network_vif_security_group.db.after_commit do
    destroy_entry(
      :NetworkVifSecurityGroup,
      :interface_uuid => "if-#{network_vif_security_group.network_vif.canonical_uuid}",
      :security_group => network_vif_security_group.security_group.canonical_uuid
    )
  end
end
