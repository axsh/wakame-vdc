# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Cli
class Network < Base
  namespace :network
  M=Dcmgr::Models
  
  desc "add [options]", "Register a new network entry"
  method_option :ipv4_gw, :type => :string, :required => true, :desc => "Gateway address for IPv4 network."
  method_option :prefix, :type => :numeric, :default=>24, :desc => "IP network mask size (1 < prefix < 32)."
  method_option :domain_name, :type => :string, :desc => "DNS domain name of the network."
  method_option :dns_server, :type => :string, :desc => "IP address for DNS server of the network"
  method_option :dhcp_server, :type => :string, :desc => "IP address for DHCP server of the network"
  method_option :metadata_server, :type => :string, :desc => "IP address for metadata server of the network"
  method_option :vlan_id, :type => :numeric, :default=>0, :desc => "Tag VLAN (802.1Q) ID of the network"
  method_option :description, :type => :string, :desc => "Description for the network"
  method_option :account_id, :type => :string, :default=>'a-shpool', :aliases => "-a", :desc => "The account ID to own this."
  def add
    vlan_pk = if options[:vlan_id].to_i > 0
                vlan = VlanLease.find(:tag_id=>options[:vlan_id]) || abort("Invalid or Unknown VLAN ID: #{options[:vlan_id]}")
                vlan.id
              else
                0
              end
    
    nw = M::Network.create({:ipv4_gw => options[:ipv4_gw],
                             :prefix => options[:prefix],
                             :dns_server => options[:dns_server],
                             :domain_name => options[:domain_name],
                             :dhcp_server => options[:dhcp_server],
                             :metadata_server => options[:metadata_server],
                             :description => options[:description],
                             :account_id => options[:account_id],
                             :vlan_lease_id => vlan_pk,
                           })

    puts nw.canonical_uuid
  end

  desc "del UUID", "Deregister a network entry"
  def del(uuid)
    nw = M::Network[uuid] || abort("Unknown network UUID: #{uuid}")
    nw.delete
  rescue InvalidUUIDError => e
    abort("Invalid UUID Format: #{uuid}")
  end

  desc "modify UUID [options]", "Update network information"
  method_option :ipv4_gw, :type => :string, :desc => "Gateway address for IPv4 network."
  method_option :prefix, :type => :numeric, :desc => "IP network mask size (1 < prefix < 32)."
  method_option :domain_name, :type => :string, :desc => "DNS domain name of the network."
  method_option :dns_server, :type => :string, :desc => "IP address for DNS server of the network"
  method_option :dhcp_server, :type => :string, :desc => "IP address for DHCP server of the network"
  method_option :metadata_server, :type => :string, :desc => "IP address for metadata server of the network"
  method_option :vlan_id, :type => :numeric, :desc => "Tag VLAN (802.1Q) ID of the network"
  method_option :description, :type => :string, :desc => "Description for the network"
  method_option :account_id, :type => :string, :aliases => "-a", :desc => "The account ID to own this."
  def modify(uuid)
    nw = M::Network[uuid] || abort("Unknown network UUID: #{uuid}")
    nw.set_only(options, [:ipv4_gw, :prefix, :domain_name, :dns_server, :dhcp_server, :metadata_server, :vlan_id, :description, :account_id])
    nw.save_changes
  rescue InvalidUUIDError => e
    abort("Invalid UUID Format: #{uuid}")
  end

  desc "nat UUID [options]", "Set or clear nat mapping for a network."
  method_option :nat_network_id, :type => :string, :aliases => "-n", :desc => "The network that this network will be natted to."
  method_option :clear, :type => :boolean, :aliases => "-c", :desc => "Clears a previously natted network."
  def nat(uuid)
    in_nw = M::Network[uuid] || abort("Unknown network UUID: #{uuid}")
    ex_nw = M::Network[options[:nat_network_id]] || abort("Unknown network UUID: #{uuid}") unless options[:nat_network_id].nil?

    if options[:clear] then
      in_nw.set_only({:nat_network_id => nil},:nat_network_id)
      in_nw.save_changes
    else
      in_nw.set_only({:nat_network_id => ex_nw.id},:nat_network_id)
      in_nw.save_changes
    end
  rescue InvalidUUIDError => e
    abort("Invalid UUID Format: #{uuid}")
  end

  desc "show [UUID] [options]", "Show network(s)"
  method_option :vlan_id, :type => :numeric, :aliases => "-l", :desc => "Show networks in the VLAN ID"
  method_option :account_id, :type => :string, :aliases => "-a", :desc => "Show networks with the account"
  def show(uuid=nil)
    if uuid
      nw = M::Network[uuid] || raise(Thor::Error, "Unknown network UUID: #{uuid}")
      puts ERB.new(<<__END, nil, '-').result(binding)
Network UUID: <%= nw.canonical_uuid %>

Tag VLAN: <%= nw.vlan_lease_id == 0 ? 'none' : nw.vlan_lease.tag_id %>
IPv4:
  Network address: <%= nw.ipaddress.network %>/<%= nw.prefix %>
  Gateway address: <%= nw.ipv4_gw %>
DHCP Information:
  DHCP Server: <%= nw.dhcp_server %>
  DNS Server: <%= nw.dns_server %>
<%- if nw.metadata_server -%>
  Metadata Server: <%= nw.metadata_server %>
<%- end -%>
<%- if nw.description -%>
Description:
  <%= nw.description %>
<%- end -%>
__END
    else
      cond = {}
      cond[:account_id]= options[:account_id] if options[:account_id]
      if options[:vlan_id]
        vlan = VlanLease.find(:tag_id=>options[:vlan_id]) || abort("Unknown Tag VLAN ID: #{options[:vlan_id]}")
        cond[:vlan_lease_id] = vlan.id
      end

      nw = M::Network.filter(cond).all
      puts ERB.new(<<__END, nil, '-').result(binding)
<%- nw.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.ipaddress.network %>/<%= row.prefix %>\t<%= (row.vlan_lease && row.vlan_lease.tag_id) %>
<%- } -%>
__END
    end
  end

  desc "show_lease UUID", "Show IPs used in the network"
  def show_lease(uuid)
    nw = M::Network[uuid] || abort("Unknown network UUID: #{uuid}")

    print ERB.new(<<__END, nil, '-').result(binding)
<%- nw.ip_lease_dataset.order(:ipv4).all.each { |l| -%>
<%= "%-20s  %-15s" % [l.ipv4, M::IpLease::TYPE_MESSAGES[l.alloc_type]] %>
<%- } -%>
__END
  end

  desc "add_reserved UUID IPADDR", "Add reserved IP to the network"
  def add_reserved(uuid, ipaddr)
    nw = M::Network[uuid] || abort("Unknown network UUID: #{uuid}")

    if nw.ipaddress.include?(IPAddress(ipaddr))
      nw.ip_lease_dataset.add_reserved(ipaddr)
    else
      abort("IP address is out of range: #{ipaddr} => #{nw.ipaddress.network}/#{nw.ipaddress.prefix}")
    end
  rescue => e
    abort(e.message)
  end

  desc "del_reserved UUID IPADDR", "Delete reserved IP from the network"
  def del_reserved(uuid, ipaddr)
    nw = M::Network[uuid] || abort("Unknown network UUID: #{uuid}")

    if nw.ip_lease_dataset.filter(:ipv4=>ipaddr).delete == 0
      abort("The IP is not reserved in network #{uuid}: #{ipaddr}")
    end
  rescue => e
    abort(e.message)
  end
end
end
