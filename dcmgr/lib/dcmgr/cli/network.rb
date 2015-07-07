# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Cli
class Network < Base
  namespace :network
  M=Dcmgr::Models

  no_tasks {
    include Dcmgr::Constants::Network

    @@conf = Dcmgr::Configurations.dcmgr

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

    def self.common_options
      method_option :uuid, :type => :string, :desc => "UUID of the network"
      method_option :ipv4_network, :type => :string, :desc => "IPv4 network address"
      method_option :ipv4_gw, :type => :string, :desc => "Gateway address for IPv4 network"
      method_option :prefix, :type => :numeric, :desc => "IP network mask size (1 < prefix < 32)"
      method_option :domain, :type => :string, :desc => "DNS domain name of the network"
      method_option :dns, :type => :string, :desc => "IP address for DNS server of the network"
      method_option :dhcp, :type => :string, :desc => "IP address for DHCP server of the network"
      method_option :metadata, :type => :string, :desc => "IP address for metadata server of the network"
      method_option :metadata_port, :type => :string, :desc => "Port for the metadata server of the network"
      method_option :bandwidth, :type => :numeric,  :desc => "The maximum bandwidth for the network in Mbit/s"
      method_option :description, :type => :string,  :desc => "Description for the network"
      method_option :account_id, :type => :string, :desc => "The account ID to own this"
      method_option :metric, :type => :numeric, :desc => "Routing priority order of this network segment"
      method_option :network_mode, :type => :string, :desc => "Network mode: #{NETWORK_MODES.join(', ')}"
      method_option :service_type, :type => :string, :desc => "Service type of the network. (#{@@conf.service_types.keys.sort.join(', ')})"
      method_option :display_name, :type => :string, :desc => "Display name of the network"
      method_option :ip_assignment, :type => :string, :desc => "How to assign the IP address of the network"
    end
  }

  desc "add [options]", "Register a new network entry"
  common_options
  method_options[:ipv4_network].required = true
  method_options[:prefix].required = true
  method_options[:account_id].default = 'a-shpoolxx'
  method_options[:metric].default = 100
  method_options[:network_mode].default = 'securitygroup'
  method_options[:service_type].default = @@conf.default_service_type
  method_options[:ip_assignment].default = 'asc'
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
  common_options
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
Metric: <%= nw.metric %>
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

  #
  # Network Vifs
  #
  class VifOps < Base
    namespace :vif
    M=Dcmgr::Models

    desc "add UUID", "Register a new vif"
    method_option :ipv4, :type => :string, :required => true, :desc => "The IP address"
    def add(nw_uuid)
      nw = M::Network[nw_uuid] || UnknownUUIDError.raise(nw_uuid)
      puts nw.add_service_vif(options[:ipv4]).canonical_uuid
    end

    desc "add-external-ip UUID IP", "Add an external IP to vif"
    def add_external_ip(vif_uuid, ip_uuid)
      vif = M::NetworkVif[vif_uuid] || UnknownUUIDError.raise(nw_uuid)
      ip_handle = M::IpHandle[ip_uuid] || UnknownUUIDError.raise(ip_uuid)
      ip_lease = ip_handle.ip_lease || Error.raise("No NetworkVifIpLease found.", 100)

      vif.network || Error.raise("Network Vif is not attached to a network.", 100)
      ip_lease.network || Error.raise("IP lease is not attached to a network.", 100)

      fields = {
        :route_type => 'external-ip',
        :outer_network_id => ip_lease.network.id,
        :inner_network_id => vif.network.id,
        :inner_vif_id => vif.id,

        :create_options => {
          :outer => {
            :find_service => 'external-ip',
            :ip_handle => ip_handle,
          },
          :inner => {
            :find_ipv4 => :vif_first,
          }
        }
      }

      M::NetworkRoute.create(fields)
    end

    desc "add-ip UUID IP", "Add an IP handle to vif"
    method_option :allow_multiple, :type => :boolean, :required => false, :desc => "Allow adding multiple IP leases to the vif"
    def add_ip(vif_uuid, ip_uuid)
      vif = M::NetworkVif[vif_uuid] || UnknownUUIDError.raise(nw_uuid)
      ip = M::IpHandle[ip_uuid] || UnknownUUIDError.raise(ip_uuid)
      ip_lease = ip.ip_lease || Error.raise("No NetworkVifIpLease found.")

      vif.network == ip_lease.network || Error.raise("Vif and IP lease's network must match.", 100)

      fields = {
        :ip_lease => ip_lease,
        :allow_multiple => options[:allow_multiple],
        :attach_network => true,
      }

      result = vif.add_ip_lease(fields)
      puts result.to_hash if result
    end

    desc "remove-ip UUID IP", "Add an IP handle to vif"
    def remove_ip(vif_uuid, ip_uuid)
      vif = M::NetworkVif[vif_uuid] || UnknownUUIDError.raise(nw_uuid)
      ip = M::IpHandle[ip_uuid] || UnknownUUIDError.raise(ip_uuid)
      ip_lease = ip.ip_lease || Error.raise("No NetworkVifIpLease found.", 100)

      fields = {
        :ip_lease => ip_lease,
        # :allow_multiple => options[:allow_multiple],
        # :attach_network => true,
      }

      vif.remove_ip_lease(fields) || Error.raise("Could not remove IP lease from vif.", 100)
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

  #
  # IP Pools
  #
  class PoolOps < Base
    namespace :pool
    M=Dcmgr::Models

    desc "add [options]", "Add new IP pool."
    method_option :account_id, :type => :string, :default=>'a-shpoolxx', :required => true, :desc => "The account ID to own this"
    method_option :uuid, :type => :string, :required => false, :desc => "UUID of the IP pool"
    method_option :display_name, :type => :string, :required => true, :desc => "Display name for the IP pool"
    method_option :expire_initial, :type => :numeric, :required => false, :desc => "Expiration time of newly created IP handles (seconds)"
    method_option :expire_released, :type => :numeric, :required => false, :desc => "Expiration time of released IP handles (seconds)"
    def add()
      fields = {
        :account_id => options[:account_id],
        :display_name => options[:display_name],
      }
      fields[:uuid] = options[:uuid] if options[:uuid]
      fields[:expire_initial] = options[:expire_initial] if options[:expire_initial]
      fields[:expire_released] = options[:expire_released] if options[:expire_released]

      puts super(M::IpPool, fields)
    end

    desc "add-dcn POOL DCN [options]", "Add DC Network to IP pool."
    def add_dcn(pool_uuid, dcn_uuid)
      pool = M::IpPool[pool_uuid] || UnknownUUIDError.raise(pool_uuid)

      if M::DcNetwork.check_uuid_format(dcn_uuid)
        dcn = M::DcNetwork[dcn_uuid]
      else
        dcn = M::DcNetwork.find(:name => dcn_uuid)
      end

      dcn || UnknownUUIDError.raise(dcn_uuid)

      fields = {
        :ip_pool_id => pool.id,
        :dc_network_id => dcn.id,
      }

      M::IpPoolDcNetwork.create(fields)
    end

    desc "del-dcn POOL DCN [options]", "Remove DC Network from IP pool."
    def del_dcn(pool_uuid, dcn_uuid)
      pool = M::IpPool[pool_uuid] || UnknownUUIDError.raise(pool_uuid)

      if M::DcNetwork.check_uuid_format(dcn_uuid)
        dcn = M::DcNetwork[dcn_uuid]
      else
        dcn = M::DcNetwork.find(:name => dcn_uuid)
      end

      dcn || UnknownUUIDError.raise(dcn_uuid)

      fields = {
        :ip_pool_id => pool.id,
        :dc_network_id => dcn.id,
      }

      assoc = M::IpPoolDcNetwork.find(fields)
      assoc && assoc.destroy
    end

    desc "acquire POOL [options]", "Acquire IP lease and add it to the IP pool."
    method_option :network_id, :type => :string, :required => false, :desc => "UUID of the network to lease from"
    def acquire(pool_uuid)
      ip_pool = M::IpPool[pool_uuid] || UnknownUUIDError.raise(pool_uuid)
      network = nil

      if options[:network_id]
        network = M::Network[options[:network_id]] || UnknownUUIDError.raise(options[:network_id])
      end

      network || Error.raise("Could not find appropriate network for leasing an IP.", 100)

      st = Dcmgr::Scheduler.service_type(@@conf.default_service_type)
      lease = st.ip_address.schedule({:network => network, :ip_pool => ip_pool})

      puts "#{lease.ip_handle.canonical_uuid} #{lease.ipv4_s}"
    end

    protected
    def self.basename
      "vdc-manage #{Network.namespace} #{self.namespace}"
    end
  end
  register PoolOps, 'pool', "pool [options]", "Maintain IP pool information"

  class HandleOps < Base
    namespace :handle
    M=Dcmgr::Models

    desc "expire-handles", "Expire IP handles."
    def expire_handles
      M::IpHandle.dataset.not_leased.expired.alives.each { |handle|
        p "#{handle.canonical_uuid}: #{handle.ip_lease.network.canonical_uuid} #{handle.ip_lease.ipv4_s}"

        handle.destroy
      }
    end

    protected
    def self.basename
      "vdc-manage #{Network.namespace} #{self.namespace}"
    end
  end
  register HandleOps, 'handle', "handle [options]", "Maintain IP handle information"

  #
  # Network Routes
  #
  class RouteOps < Base
    namespace :route
    M=Dcmgr::Models

    no_tasks {
      def from_uuid(uuid)
        nw = vif = ip_lease = nil

        case uuid
        when /^nw-/
          nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)
        when /^vif-/
          vif = M::NetworkVif[uuid] || UnknownUUIDError.raise(uuid)
          nw = vif.network || Error.raise("No network associated with uuid: #{vif.canonical_uuid}")
        when /^ip-/
          ip_handle = M::IpHandle[uuid] || UnknownUUIDError.raise(uuid)
          ip_lease = ip_handle.ip_lease
          nw = ip_lease.network
          vif = ip_lease.network_vif
        else
          UnknownUUIDError.raise(uuid)
        end

        [nw, vif, ip_lease]
      end

      def routes_dataset(outer_uuid, inner_uuid, outer, inner)
        ds = M::NetworkRoute.dataset

        if outer[2]
          ds = ds.where(:network_routes__outer_lease_id => outer[2].id)
        elsif outer[1]
          ds = ds.join_with_outer_ip_leases.where(:outer_ip_leases__network_vif_id => outer[1].id)
        elsif outer[0]
          ds = ds.join_with_outer_ip_leases.where(:outer_ip_leases__network_id => outer[0].id)
        else
          UnknownUUIDError.raise(outer_uuid)
        end

        if inner[2]
          ds = ds.where(:network_routes__inner_lease_id => inner[2].id)
        elsif inner[1]
          ds = ds.join_with_inner_ip_leases.where(:inner_ip_leases__network_vif_id => inner[1].id)
        elsif inner[0]
          ds = ds.join_with_inner_ip_leases.where(:inner_ip_leases__network_id => inner[0].id)
        else
          UnknownUUIDError.raise(inner_uuid)
        end

        ds
      end
    }

    desc "add OUTER_UUID INNER_UUID", "Add route between two networks"
    method_option :route_type, :type => :string, :required => true, :desc => "Route type"
    def add(outer_uuid, inner_uuid)
      create_options = {:outer => {}, :inner => {}}

      outer_nw, outer_vif, outer_lease = from_uuid(outer_uuid)
      inner_nw, inner_vif, inner_lease = from_uuid(inner_uuid)

      case options[:route_type]
      when 'external-ip'
        create_options[:outer][:lease_ipv4] = :default if outer_lease.nil?
        create_options[:outer][:find_service] = 'external-ip'
        create_options[:inner][:find_ipv4] = :vif_first if inner_lease.nil?
      else
        Error.raise("Unknown route type.", 100)
      end

      create_options[:outer][:network] = outer_nw if outer_nw
      create_options[:inner][:network] = inner_nw if inner_nw
      create_options[:outer][:network_vif] = outer_vif if outer_vif
      create_options[:inner][:network_vif] = inner_vif if inner_vif

      route_data = {
        :route_type => options[:route_type],
        :create_options => create_options
      }

      route_data[:outer_lease_id] = outer_lease.id if outer_lease
      route_data[:inner_lease_id] = inner_lease.id if inner_lease

      result = M::NetworkRoute.create(route_data)

      shell.print_table([[route_data[:route_data],
                          result.outer_network.canonical_uuid,
                          result.outer_vif ? result.outer_vif.canonical_uuid : nil,
                          result.outer_lease.ipv4_s,
                          result.inner_network.canonical_uuid,
                          result.inner_vif ? result.inner_vif.canonical_uuid : nil,
                          result.inner_lease.ipv4_s]])
    end

    desc "del OUTER_UUID INNER_UUID", "Delete routes between two networks"
    method_option :all_route_types, :type => :boolean, :required => false, :desc => "Include all route types"
    method_option :route_type, :type => :string, :required => false, :desc => "Route type"
    def del(outer_uuid, inner_uuid)
      outer_nw, outer_vif, outer_lease = from_uuid(outer_uuid)
      inner_nw, inner_vif, inner_lease = from_uuid(inner_uuid)

      ds = routes_dataset(outer_uuid, inner_uuid, from_uuid(outer_uuid), from_uuid(inner_uuid))

      # If no route_type is supplied, require --all-route-types.
      if options[:route_type]
        ds = ds.where(:network_routes__route_type => options[:route_type])
      elsif options[:all_route_types] != true
        Error.raise("Either supply a 'route-type' or set 'all-route-types'.", 100)
      end

      table = [['Type', 'Outer NW', 'Outer Vif', 'Inner NW', 'Inner Vif']]
      ds.each { |r|
        table << [r.route_type,
                  r.outer_network ? r.outer_network.canonical_uuid : nil,
                  r.outer_vif ? r.outer_vif.canonical_uuid : nil,
                  r.outer_lease.ipv4_s,
                  r.inner_vif.network ? r.inner_vif.network.canonical_uuid : nil,
                  r.inner_vif ? r.inner_vif.canonical_uuid : nil,
                  r.inner_lease.ipv4_s]
        r.destroy
      }

      shell.print_table(table)
    end

    desc "show NW", "Show routes on network"
    def show(uuid)
      ds = (M::Network[uuid] || UnknownUUIDError.raise(uuid)).network_routes

      table = [['Type', 'Outer NW', 'Outer Vif', 'Inner NW', 'Inner Vif']]
      ds.each { |r|
        table << [r.route_type,
                  r.outer_network ? r.outer_network.canonical_uuid : nil,
                  r.outer_vif ? r.outer_vif.canonical_uuid : nil,
                  r.outer_lease.ipv4_s,
                  r.inner_vif.network ? r.inner_vif.network.canonical_uuid : nil,
                  r.inner_vif ? r.inner_vif.canonical_uuid : nil,
                  r.inner_lease.ipv4_s]
      }
      shell.print_table(table)
    end

    desc "show-between OUTER INNER", "Show routes on network"
    def show_between(outer_uuid, inner_uuid)
      outer_nw, outer_vif, outer_lease = from_uuid(outer_uuid)
      inner_nw, inner_vif, inner_lease = from_uuid(inner_uuid)

      ds = routes_dataset(outer_uuid, inner_uuid, from_uuid(outer_uuid), from_uuid(inner_uuid))

      table = [['Type', 'Outer NW', 'Outer Vif', 'Inner NW', 'Inner Vif']]
      ds.each { |r|
        table << [r.route_type,
                  r.outer_network ? r.outer_network.canonical_uuid : nil,
                  r.outer_vif ? r.outer_vif.canonical_uuid : nil,
                  r.outer_lease.ipv4_s,
                  r.inner_vif.network ? r.inner_vif.network.canonical_uuid : nil,
                  r.inner_vif ? r.inner_vif.canonical_uuid : nil,
                  r.inner_lease.ipv4_s]
      }
      shell.print_table(table)
    end

    protected
    def self.basename
      "vdc-manage #{Network.namespace} #{self.namespace}"
    end
  end
  register RouteOps, 'route', "route [options]", "Maintain routing information"

  #
  # Network Services
  #
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
          option_ipv4 = options[:ipv4]

          if options[:no_ipv4] != true
            option_ipv4 || Error.raise("IP address is required when passing network UUID.", 1)
          end

          if options[:unique] == true
            options[:service] || Error.raise("Unique service parameter requires service arg.", 1)
            get_services(uuid, {:service => options[:service]}).empty? || Error.raise("Service must be unique on network.", 1)
          end

          nw = M::Network[uuid] || UnknownUUIDError.raise(uuid)
          nw.add_service_vif(options[:ipv4])

        when /^vif-/
          options[:ipv4].nil? || Error.raise("Cannot pass IP address for VIF UUID.", 1)
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
      nw = vif.network || Error.raise("Not attached to a network: #{uuid_from}", 1)
      puts "#{vif.canonical_uuid}"

      service_data = {
        :network_vif_id => vif.id,
        :name => 'gateway',
      }

      M::NetworkService.create(service_data)
    end

    desc "external-ip NW", "Add external-ip service to network"
    # method_option :no_ip, :type => :boolean, :required => false, :desc => "Don't lease any IP address"
    def external_ip(uuid_from)
      vif = prepare_vif(uuid_from, {:unique => true, :service => 'external-ip', :no_ipv4 => true})
      nw = vif.network || Error.raise("Not attached to a network: #{uuid_from}", 1)
      puts "#{vif.canonical_uuid}"

      service_data = {
        :network_vif_id => vif.id,
        :name => 'external-ip',
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
    include Dcmgr::Constants::Network

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

    desc "add-network-mode UUID/NAME MODENAME", "Add network mode (#{NETWORK_MODES.join(', ')})"
    def add_network_mode(uuid, modename)
      dc = find_by_name_or_uuid(uuid)
      dc.offering_network_modes.push(modename)
      dc.save
    end

    desc "del-network-mode UUID/NAME MODENAME", "Delete network mode (#{NETWORK_MODES.join(', ')})"
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
<%= "%-20s  %-15s" % [l.canonical_uuid, l.name] %>
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
<%- nw.dhcp_range_dataset.each { |r| -%>
  <%= r.range_begin.to_s %> - <%= r.range_end.to_s %>
<%- } -%>
__END
      else
        cond = {}
        nw = M::Network.filter(cond).all
        print ERB.new(<<__END, nil, '-').result(binding)
<%- nw.each { |row| -%>
<%-   row.dhcp_range.each { |r| -%>
<%=     row.canonical_uuid %>\t<%= r.range_begin.to_s %>\t<%= r.range_end.to_s %>
<%-   } -%>
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
