# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Cli
class Network < Base
  namespace :network
  M=Dcmgr::Models

  no_tasks {
    def validate_ipv4_range
      @network_addr = IPAddress::IPv4.new("#{options[:ipv4_network]}/#{options[:prefix]}").network
      p @network_addr.to_s
      if options[:ipv4_gw] && !@network_addr.include?(IPAddress::IPv4.new(options[:ipv4_gw]))
        Error.raise("ipv4_gw #{options[:ipv4_gw]} is out of range from network address: #{@network_addr}")
      end
      # DHCP IP address has to be in same IP network.
      if options[:dhcp] && !@network_addr.include?(IPAddress::IPv4.new(options[:dhcp]))
        Error.raise("dhcp server address #{options[:dhcp]} is out of range from network address: #{@network_addr}")
      end
    end
    private :validate_ipv4_range

    def map_network_params
      optmap(options) { |c|
        c.option(:ipv4_network) {
          @network_addr.to_s
        }
        c.map(:domain, :domain_name)
        c.map(:dhcp, :dhcp_server)
        c.map(:dns, :dns_server)
        c.map(:metadata, :metadata_server)
        c.map(:metadata_port, :metadata_server_port)
        c.option(:vlan_id, :vlan_lease_id) {
          @vlan_pk
        }
      }
    end
    private :map_network_params
  }
  
  desc "add [options]", "Register a new network entry"
  method_option :uuid, :type => :string, :desc => "UUID of the network"
  method_option :ipv4_network, :type => :string, :required=>true, :desc => "IPv4 network address"
  method_option :ipv4_gw, :type => :string, :desc => "Gateway address for IPv4 network"
  method_option :prefix, :type => :numeric, :required => true, :desc => "IP network mask size (1 < prefix < 32)"
  method_option :domain, :type => :string, :desc => "DNS domain name of the network"
  method_option :dns, :type => :string, :desc => "IP address for DNS server of the network"
  method_option :dhcp, :type => :string, :desc => "IP address for DHCP server of the network"
  method_option :metadata, :type => :string, :desc => "IP address for metadata server of the network"
  method_option :metadata_port, :type => :string, :desc => "Port for the metadata server of the network"
  method_option :bandwidth, :type => :numeric,  :desc => "The maximum bandwidth for the network in Mbit/s"
  method_option :vlan_id, :type => :numeric, :default=>0, :desc => "Tag VLAN (802.1Q) ID of the network. 0 is for no VLAN network"
  method_option :link_interface, :type => :string, :desc => "Link interface name from virtual interfaces"
  method_option :description, :type => :string,  :desc => "Description for the network"
  method_option :account_id, :type => :string, :default=>'a-shpoolxx', :required => true, :desc => "The account ID to own this"
  method_option :metric, :type => :numeric, :default=>100, :desc => "Routing priority order of this network segment"
  def add
    @vlan_pk = if options[:vlan_id].to_i > 0
                 vlan = M::VlanLease.find(:tag_id=>options[:vlan_id]) || Error.raise("Invalid or Unknown VLAN ID: #{options[:vlan_id]}", 100)
                 vlan.id
               else
                 0
               end

    validate_ipv4_range

    fields = map_network_params

    puts super(M::Network,fields)
  end

  desc "del UUID", "Deregister a network entry"
  def del(uuid)
    super(M::Network,uuid)
  end

  desc "modify UUID [options]", "Update network information"
  method_option :ipv4_network, :type => :string, :required=>true, :desc => "IPv4 network address"
  method_option :ipv4_gw, :type => :string, :desc => "Gateway address for IPv4 network"
  method_option :prefix, :type => :numeric, :desc => "IP network mask size (1 < prefix < 32)"
  method_option :domain, :type => :string, :desc => "DNS domain name of the network"
  method_option :dns, :type => :string, :desc => "IP address for DNS server of the network"
  method_option :dhcp, :type => :string, :desc => "IP address for DHCP server of the network"
  method_option :metadata, :type => :string, :desc => "IP address for metadata server of the network"
  method_option :metadata_port, :type => :string, :desc => "Port for the metadata server of the network" 
  method_option :vlan_id, :type => :numeric, :desc => "Tag VLAN (802.1Q) ID of the network. 0 is for no VLAN network"
  method_option :link_interface, :type => :string, :desc => "Link interface name from virtual interfaces"
  method_option :bandwidth, :type => :numeric, :desc => "The maximum bandwidth for the network in Mbit/s"
  method_option :description, :type => :string, :desc => "Description for the network"
  method_option :account_id, :type => :string, :desc => "The account ID to own this"
  def modify(uuid)
    @vlan_pk = if options[:vlan_id].to_i > 0
                 vlan = M::VlanLease.find(:tag_id=>options[:vlan_id]) || Error.raise("Invalid or Unknown VLAN ID: #{options[:vlan_id]}", 100)
                 vlan.id
               else
                 0
               end
    
    validate_ipv4_range

    fields = map_network_params
    
    super(M::Network,uuid,fields)
  end

  desc "nat UUID [options]", "Set or clear nat mapping for a network"
  method_option :outside_network_id, :type => :string, :desc => "The network that this network will be natted to"
  method_option :clear, :type => :boolean, :desc => "Clears a previously natted network"
  def nat(uuid)
    in_nw = M::Network[uuid] || Error.raise("Unknown network UUID: #{uuid}", 100)
    ex_nw = M::Network[options[:outside_network_id]] || Error.raise("Unknown network UUID: #{uuid}", 100) unless options[:outside_network_id].nil?

    if options[:clear] then
      in_nw.set_only({:nat_network_id => nil},:nat_network_id)
      in_nw.save_changes
    else
      in_nw.set_only({:nat_network_id => ex_nw.id},:nat_network_id)
      in_nw.save_changes
    end
  end

  desc "show [UUID] [options]", "Show network(s)"
  method_option :vlan_id, :type => :numeric, :desc => "Show networks in the VLAN ID"
  method_option :account_id, :type => :string, :desc => "Show networks with the account"
  def show(uuid=nil)
    if uuid
      nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)
      puts ERB.new(<<__END, nil, '-').result(binding)
Network UUID:
  <%= nw.canonical_uuid %>
Tag VLAN:
  <%= nw.vlan_lease_id == 0 ? 'none' : nw.vlan_lease.tag_id %>
IPv4:
  Network address: <%= nw.ipv4_ipaddress %>/<%= nw.prefix %>
  Gateway address: <%= nw.ipv4_gw %>
<%- if nw.nat_network_id -%>
  Outside NAT network address: <%= nw.nat_network.ipv4_ipaddress %>/<%= nw.nat_network.prefix %> (<%= nw.nat_network.canonical_uuid %>)
<%- end -%>
DHCP Information:
  DHCP Server: <%= nw.dhcp_server %>
  DNS Server: <%= nw.dns_server %>
<%- if nw.metadata_server -%>
  Metadata Server: <%= nw.metadata_server %>
<%- end -%>
Bandwidth:
<%- if nw.bandwidth.nil? -%>
  unlimited
<%- else -%>
  <%= nw.bandwidth %> Mbit/s
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
        vlan = M::VlanLease.find(:tag_id=>options[:vlan_id]) || abort("Unknown Tag VLAN ID: #{options[:vlan_id]}")
        cond[:vlan_lease_id] = vlan.id
      end

      nw = M::Network.filter(cond).all
      puts ERB.new(<<__END, nil, '-').result(binding)
<%- nw.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.ipv4_ipaddress %>/<%= row.prefix %>\t<%= (row.vlan_lease && row.vlan_lease.tag_id) %>
<%- } -%>
__END
    end
  end

  desc "leases UUID", "Show IPs used in the network"
  def leases(uuid)
    nw = M::Network[uuid] || Error.raise("Unknown network UUID: #{uuid}", 100)

    print ERB.new(<<__END, nil, '-').result(binding)
<%- nw.ip_lease_dataset.order(:ipv4).all.each { |l| -%>
<%= "%-20s  %-15s" % [l.ipv4, M::IpLease::TYPE_MESSAGES[l.alloc_type]] %>
<%- } -%>
__END
  end

  desc "reserve UUID", "Add reserved IP to the network"
  method_option :ipv4, :type => :string, :required => true, :desc => "The ip address to reserve"
  def reserve(uuid)
    nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)
    
    if nw.include?(IPAddress(options[:ipv4]))
      nw.ip_lease_dataset.add_reserved(options[:ipv4])
    else
      Error.raise("IP address is out of range: #{options[:ipv4]} => #{nw.ipv4_ipaddress}/#{nw.prefix}",100)
    end
  end

  desc "release UUID", "Release a reserved IP from the network"
  method_option :ipv4, :type => :string, :required => true, :desc => "The ip address to release"
  def release(uuid)
    nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)

    if nw.ip_lease_dataset.filter(:ipv4=>options[:ipv4]).delete == 0
      Error.raise("The IP is not reserved in network #{uuid}: #{options[:ipv4]}", 100)
    end
  end

  desc "forward UUID PHYSICAL", "Set forward interface for network"
  def forward(uuid, phynet)
    nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)
    phy = M::PhysicalNetwork.find(:name=>phynet) || Error.raise("Unknown physical network: #{phynet}")
    nw.physical_network = phy
    nw.save
  end

  class PhyOps < Base
    namespace :phy
    M=Dcmgr::Models
    
    desc "add NAME [options]", "Add new physical network"
    method_option :null, :type => :boolean, :desc => "Do not attach to any physical interfaces"
    method_option :interface, :type => :string, :desc => "Physical interface name on host nodes"
    method_option :description, :type => :string, :desc => "Description for the physical network"
    def add(name)
      M::PhysicalNetwork.find(:name=>name) && Error.raise("Duplicate physical network name: #{name}", 100)
      phy = options[:null] ? nil : (options[:interface] || name)

      fields={
        :name=>name,
        :interface=>phy,
        :description=>options[:description],
      }
      M::PhysicalNetwork.create(fields)
    end

    desc "modify NAME [options]", "Modify physical network parameters"
    method_option :null, :type => :boolean, :desc => "Do not attach to any physical interfaces"
    method_option :interface, :type => :string, :desc => "Physical interface name on host nodes"
    method_option :description, :type => :string, :desc => "Description for the physical network"
    def modify(name)
      phy = M::PhysicalNetwork.find(:name=>name) || Error.raise("Unknown physical network: #{name}", 100)
      phy = options[:null] ? nil : options[:interface]

      phy.update({
                   :interface=>phy,
                   :description=>options[:description],
                 })
    end

    desc "del NAME [options]", "Delete physical network"
    def del(name)
      phy = M::PhysicalNetwork.find(:name=>name) || Error.raise("Unknown physical network: #{name}", 100)
      phy.destroy
    end
    
    desc "show [NAME]", "Show/List physical network"
    def show(name=nil)
      if name
        phy = M::PhysicalNetwork.find(:name=>name) || Error.raise("Unknown physical network: #{name}", 100)
        print ERB.new(<<__END, nil, '-').result(binding)
Physical Network:       <%= phy.name %>
Forwarding Interface:   <%= phy.interface.nil? ? 'none': phy.interface %>
<%- if phy.description -%>
Description:
<%= phy.description %>
<%- end -%>
__END
      else
    print ERB.new(<<__END, nil, '-').result(binding)
<%- M::PhysicalNetwork.order(:id).all.each { |l| -%>
<%= "%-20s  %-15s" % [l.name, l.interface] %>
<%- } -%>
__END
      end
    end
    
    protected
    def self.basename
      "vdc-manage #{Network.namespace} #{self.namespace}"
    end
  end
  register PhyOps, 'phy', "phy [options]", "Maintain physical network"

  class DhcpOps < Base
    namespace :dhcp
    M=Dcmgr::Models
    
    desc "addrange UUID ADDRESS_BEGIN ADDRESS_END", "Add dynamic IP address range to the network"
    def addrange(uuid, range_begin, range_end)
      nw = M::Network[uuid] || UnknownUUIDEntry.raise
      nw.add_ipv4_dynamic_range(range_begin, range_end)
    end

    desc "delrange UUID ADDRESS_BEGIN ADDRESS_END", "Delete dynamic IP address range from the network"
    def delrange(uuid, range_begin, range_end)
      nw = M::Network[uuid] || UnknownUUIDEntry.raise
      nw.del_ipv4_dynamic_range(range_begin, range_end)
    end
    
    protected
    def self.basename
      "vdc-manage #{Network.namespace} #{self.namespace}"
    end
  end
  register DhcpOps, 'dhcp', "dhcp [options]", "Maintain dhcp parameters"
  
end
end
