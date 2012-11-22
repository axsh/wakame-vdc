# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Cli
class Network < Base
  namespace :network
  M=Dcmgr::Models
  NConst=Dcmgr::Constants::Network

  no_tasks {
    def validate_ipv4_range
      @network_addr = IPAddress::IPv4.new("#{options[:ipv4_network]}/#{options[:prefix]}").network
      if options[:ipv4_gw] && !@network_addr.include?(IPAddress::IPv4.new(options[:ipv4_gw]))
        Error.raise("ipv4_gw #{options[:ipv4_gw]} is out of range from network address: #{@network_addr}", 100)
      end
      # DHCP IP address has to be in same IP network.
      if options[:dhcp] && !@network_addr.include?(IPAddress::IPv4.new(options[:dhcp]))
        Error.raise("dhcp server address #{options[:dhcp]} is out of range from network address: #{@network_addr}", 100)
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
  method_option :description, :type => :string,  :desc => "Description for the network"
  method_option :account_id, :type => :string, :default=>'a-shpoolxx', :required => true, :desc => "The account ID to own this"
  method_option :metric, :type => :numeric, :default=>100, :desc => "Routing priority order of this network segment"
  method_option :network_mode, :type => :string, :default=>'securitygroup', :desc => "Network mode: #{NConst::NETWORK_MODES.join(', ')}"
  method_option :service_type, :type => :string, :default=>Dcmgr.conf.default_service_type, :desc => "Service type of the network. (#{Dcmgr.conf.service_types.keys.sort.join(', ')})"
  method_option :display_name, :type => :string, :required => true, :desc => "Display name of the network"
  method_option :ip_assignment, :type => :string, :default=>'asc', :desc => "How to assign the IP address of the network"
  def add
    validate_ipv4_range

    fields = map_network_params

    puts super(M::Network,fields)
  end

  desc "del UUID", "Deregister a network entry"
  def del(uuid)
    super(M::Network,uuid)
  end

  desc "modify UUID [options]", "Update network information"
  method_option :ipv4_network, :type => :string, :desc => "IPv4 network address"
  method_option :ipv4_gw, :type => :string, :desc => "Gateway address for IPv4 network"
  method_option :prefix, :type => :numeric, :desc => "IP network mask size (1 < prefix < 32)"
  method_option :domain, :type => :string, :desc => "DNS domain name of the network"
  method_option :dns, :type => :string, :desc => "IP address for DNS server of the network"
  method_option :dhcp, :type => :string, :desc => "IP address for DHCP server of the network"
  method_option :metadata, :type => :string, :desc => "IP address for metadata server of the network"
  method_option :metadata_port, :type => :string, :desc => "Port for the metadata server of the network"
  method_option :bandwidth, :type => :numeric, :desc => "The maximum bandwidth for the network in Mbit/s"
  method_option :description, :type => :string, :desc => "Description for the network"
  method_option :account_id, :type => :string, :desc => "The account ID to own this"
  method_option :network_mode, :type => :string, :desc => "Network mode: #{NConst::NETWORK_MODES.join(', ')}"
  method_option :service_type, :type => :string, :desc => "Service type of the network. (#{Dcmgr.conf.service_types.keys.sort.join(', ')})"
  method_option :display_name, :type => :string, :desc => "Display name of the network"
  def modify(uuid)
    validate_ipv4_range if options[:ipv4_network]

    fields = map_network_params

    super(M::Network,uuid,fields)
  end

  desc "show [UUID] [options]", "Show network(s)"
  method_option :account_id, :type => :string, :desc => "Show networks with the account"
  def show(uuid=nil)
    if uuid
      nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)
      puts ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= nw.canonical_uuid %>
Name: <%= nw.display_name %>
Network Mode: <%= nw.network_mode %>
Service Type: <%= nw.service_type %>
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

      nw = M::Network.filter(cond).all
      puts ERB.new(<<__END, nil, '-').result(binding)
<%- nw.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.ipv4_ipaddress %>/<%= row.prefix %>
<%- } -%>
__END
    end
  end

  desc "leases UUID", "Show IPs used in the network"
  def leases(uuid)
    nw = M::Network[uuid] || Error.raise("Unknown network UUID: #{uuid}", 100)

    print ERB.new(<<__END, nil, '-').result(binding)
<%- nw.network_vif_ip_lease_dataset.order(:ipv4).all.each { |l| -%>
<%= "%-20s  %-15s" % [l.ipv4, M::NetworkVifIpLease::TYPE_MESSAGES[l.alloc_type]] %>
<%- } -%>
__END
  end

  desc "reserve UUID", "Add reserved IP to the network"
  method_option :ipv4, :type => :string, :required => true, :desc => "The ip address to reserve"
  def reserve(uuid)
    nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)

    reservaddr =  begin
                    IPAddress(options[:ipv4])
                  rescue ArgumentError => e
                    Error.raise("Invalid IP address: #{options[:ipv4]}: #{e.message}", 100)
                  end
    if nw.include?(reservaddr)
      nw.network_vif_ip_lease_dataset.add_reserved(reservaddr.to_s)
    else
      Error.raise("IP address is out of range: #{options[:ipv4]} => #{nw.ipv4_ipaddress}/#{nw.prefix}",100)
    end
  end

  desc "release UUID", "Release a reserved IP from the network"
  method_option :ipv4, :type => :string, :required => true, :desc => "The ip address to release"
  def release(uuid)
    nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)

    releaseaddr = begin
                    IPAddress(options[:ipv4])
                  rescue ArgumentError => e
                    Error.raise("Invalid IP address: #{options[:ipv4]}: #{e.message}", 100)
                  end
    if nw.include?(releaseaddr)
      if nw.network_vif_ip_lease_dataset.delete_reserved(releaseaddr.to_s) == 0
        Error.raise("The IP is not reserved in network #{uuid}: #{options[:ipv4]}", 100)
      end
    else
      Error.raise("IP address is out of range: #{options[:ipv4]} => #{nw.ipv4_ipaddress}/#{nw.prefix}",100)
    end
  end

  desc "forward UUID DCNET", "Set forward interface for the network"
  def forward(uuid, dcnet)
    nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)
    dc = M::DcNetwork.find(:name=>dcnet) || Error.raise("Unknown dc network: #{dcnet}")
    nw.dc_network = dc
    nw.save
  end

  class VifOps < Base
    namespace :vif
    M=Dcmgr::Models

    desc "add UUID", "Register a new vif"
    method_option :ipv4, :type => :string, :required => true, :desc => "The ip address"
    def add(nw_uuid)
      nw = M::Network[nw_uuid] || UnknownUUIDError.raise(nw_uuid)
      puts nw.add_service_vif(options[:ipv4]).canonical_uuid
    end

    desc "show NW", "Show network vifs on network"
    def show(nw_uuid)
      nw = M::Network[nw_uuid] || UnknownUUIDError.raise(nw_uuid)
      ds = M::NetworkVif.where(:network_id => nw.id)

      table = [['Vif', 'Network', 'Instance', 'IPv4', 'NAT IPv4']]
      ds.each { |r|
        table << [r.canonical_uuid,
                  r.network.canonical_uuid,
                  r.instance ? r.instance.canonical_uuid : nil,
                  r.direct_ip_lease.first ? r.direct_ip_lease.first.ipv4 : nil,
                  r.nat_ip_lease.first ? r.nat_ip_lease.first.ipv4 : nil,
                 ]
      }
      shell.print_table(table)
    end

    protected
    def self.basename
      "vdc-manage #{Network.namespace} #{self.namespace}"
    end
  end
  register VifOps, 'vif', "vif [options]", "Maintain virtual interfaces"

  class ServiceOps < Base
    namespace :service
    M=Dcmgr::Models

    no_tasks {
      def get_services(uuid, options)
        case uuid
        when /^nw-/
          filter = {}
          filter[:name] = options[:service] if options[:service]

          nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)
          nw.network_service(filter)

        else
          InvalidUUIDError.raise(uuid)
        end
      end

      def prepare_vif(uuid, options)
        case uuid
        when /^nw-/
          options[:ipv4] || Error.raise("IP address is required when passing network UUID.")

          nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)
          nw.add_service_vif(options[:ipv4])

        when /^vif-/
          options[:ipv4].nil? || Error.raise("Cannot pass IP address for VIF UUID.")
          M::NetworkVif[uuid] || UnknownUUIDError.raise(uuid)
        else
          InvalidUUIDError.raise(uuid)
        end
      end
    }

    desc "dhcp VIF", "Set DHCP service for network"
    method_option :ipv4, :type => :string, :required => false, :desc => "The ip address"
    def dhcp(uuid)
      vif = prepare_vif(uuid, options)
      puts vif.canonical_uuid

      service_data = {
        :network_vif_id => vif.id,
        :name => 'dhcp',
        :incoming_port => 67,
        :outgoing_port => 68,
      }

      M::NetworkService.create(service_data)
    end

    desc "dns VIF", "Set DNS service for network"
    method_option :ipv4, :type => :string, :required => false, :desc => "The ip address"
    def dns(uuid)
      vif = prepare_vif(uuid, options)
      puts vif.canonical_uuid

      service_data = {
        :network_vif_id => vif.id,
        :name => 'dns',
        :incoming_port => 53,
      }

      M::NetworkService.create(service_data)
    end

    desc "gateway VIF", "Set gateway for network"
    method_option :ipv4_from, :type => :string, :required => false, :desc => "The ip address"
    def gateway(uuid_from)
      vif = prepare_vif(uuid_from, {:ipv4 => options[:ipv4_from]})
      nw = vif.network || Error.raise("Not attached to a network: #{uuid_from}")
      puts "#{vif.canonical_uuid}"

      service_data = {
        :network_vif_id => vif.id,
        :name => 'gateway',
      }

      M::NetworkService.create(service_data)
    end

    desc "show NW", "Show services on network"
    method_option :service, :type => :string, :required => false, :desc => "The service name"
    def show(uuid)
      ds = get_services(uuid, options)

      table = [['Vif', 'Name', 'IPv4', 'NAT IPv4', 'Incoming Port', 'Outgoing Port']]
      ds.each { |r|
        vif = r.network_vif

        table << [vif.canonical_uuid,
                  r.name,
                  vif.direct_ip_lease.first ? vif.direct_ip_lease.first.ipv4 : nil,
                  vif.nat_ip_lease.first ? vif.nat_ip_lease.first.ipv4 : nil,
                  r.incoming_port,
                  r.outgoing_port]
      }
      shell.print_table(table)
    end

    desc "remove NW", "Remove services on network"
    method_option :service, :type => :string, :required => true, :desc => "The service name"
    def remove(uuid)
      ds = get_services(uuid, options)

      table = []
      ds.each { |r|
        table << [r.network_vif.canonical_uuid, r.name]
        r.destroy
      }
      shell.print_table(table)
    end

    protected
    def self.basename
      "vdc-manage #{Network.namespace} #{self.namespace}"
    end
  end
  register ServiceOps, 'service', "service [options]", "Maintain network services"

  class DcOps < Base
    namespace :dc
    M=Dcmgr::Models

    desc "add NAME [options]", "Add new dc network. (NAME must be unique)"
    method_option :uuid, :type => :string, :desc => "UUID of the network"
    method_option :description, :type => :string, :desc => "Description for the dc network"
    method_option :allow_new_networks, :type => :boolean, :default => false, :desc => "Allow user to create new networks"
    def add(name)
      M::DcNetwork.find(:name=>name) && Error.raise("Duplicate dc network name: #{name}", 100)

      fields=options.dup
      fields[:name]=name
      puts super(M::DcNetwork, fields)
    end

    desc "modify UUID/NAME [options]", "Modify dc network parameters"
    method_option :uuid, :type => :string, :desc => "UUID of the network"
    method_option :name, :type => :string, :desc => "Name of the network"
    method_option :description, :type => :string, :desc => "Description for the dc network"
    def modify(uuid)
      dc = find_by_name_or_uuid(uuid)
      super(M::DcNetwork, dc.canonical_uuid, options.dup)
    end

    desc "add-network-mode UUID/NAME MODENAME", "Add network mode (#{NConst::NETWORK_MODES.join(', ')})"
    def add_network_mode(uuid, modename)
      dc = find_by_name_or_uuid(uuid)
      dc.offering_network_modes.push(modename)
      dc.save
    end

    desc "del-network-mode UUID/NAME MODENAME", "Delete network mode (#{NConst::NETWORK_MODES.join(', ')})"
    def del_network_mode(uuid, modename)
      dc = find_by_name_or_uuid(uuid)
      dc.offering_network_modes.delete(modename)
      dc.save
    end

    desc "del UUID/NAME [options]", "Delete dc network"
    def del(name)
      dc = find_by_name_or_uuid(name)
      dc.destroy
    end

    desc "show [UUID/NAME]", "Show/List dc network"
    def show(name=nil)
      if name
        dc = find_by_name_or_uuid(uuid)
        print ERB.new(<<__END, nil, '-').result(binding)
DC Network UUID: <%= dc.canonical_uuid %>
DC Network Name: <%= dc.name %>
Offering Network Mode: <%= dc.offering_network_modes.join(', ') %>
<%- if dc.description -%>
Description:
<%= dc.description %>
<%- end -%>
__END
      else
    print ERB.new(<<__END, nil, '-').result(binding)
<%- M::DcNetwork.order(:id).all.each { |l| -%>
<%= "%-20s  %-15s" % [l.canoical_uuid, l.name] %>
<%- } -%>
__END
      end
    end

    protected
    def self.basename
      "vdc-manage #{Network.namespace} #{self.namespace}"
    end

    no_tasks {
      def find_by_name_or_uuid(name)
        begin
          M::DcNetwork[name]
        rescue
          M::DcNetwork.find(:name=>name) || Error.raise("Unknown dc network: #{name}", 100)
        end
      end
    }
  end
  register DcOps, 'dc', "dc [options]", "Maintain dc network"

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

    desc "show [UUID]", "Show dynamic IP address range"
    def show(uuid=nil)
      if uuid
        nw = M::Network[uuid] || UnknownUUIDEntry.raise
        print ERB.new(<<__END, nil, '-').result(binding)
Network UUID:
  <%= nw.canonical_uuid %>
Dynamic IP Address Range:
<%- unless nw.ipv4_u32_dynamic_range_array.empty? -%>
  <%= IPAddress::IPv4::parse_u32(nw.ipv4_u32_dynamic_range_array.shift) %> - <%= IPAddress::IPv4::parse_u32(nw.ipv4_u32_dynamic_range_array.last) %>
<%- end -%>
__END
      else
        cond = {}
        nw = M::Network.filter(cond).all
        print ERB.new(<<__END, nil, '-').result(binding)
<%- nw.each { |row| -%>
<%= row.canonical_uuid %>\t<%= IPAddress::IPv4::parse_u32(row.ipv4_u32_dynamic_range_array.shift) %>\t<%= IPAddress::IPv4::parse_u32(row.ipv4_u32_dynamic_range_array.last) %>
<%- } -%>
__END
      end
    end

    protected
    def self.basename
      "vdc-manage #{Network.namespace} #{self.namespace}"
    end
  end
  register DhcpOps, 'dhcp', "dhcp [options]", "Maintain dhcp parameters"

end
end
