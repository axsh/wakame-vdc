# -*- coding: utf-8 -*-

require 'ipaddress'
require 'dcmgr/endpoints/12.03/responses/network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/networks' do

  def get_service_address(network_address, service_ipv4 = nil)
    return network_address.first.to_s if service_ipv4.nil? || service_ipv4.empty?

    service_address = IPAddress::IPv4.new(service_ipv4)
    raise E::NetworkVifInvalidAddress if service_address.nil? || service_address.octets[3] == 0

    return service_address.to_s
  end

  get do
    # description "List networks in account"
    # params start, fixnum, optional
    # params limit, fixnum, optional
    ds = M::Network.dataset

    ds = ds.filter(:networks__account_id => params[:account_id]) if params[:account_id]
    ds = ds.filter(:networks__display_name => params[:display_name]) if params[:display_name]
    ds = ds.where_with_services(:network_services__name => params[:has_service]) if params[:has_service]
    ds = ds.where_with_dc_networks(:dc_networks__uuid => M::DcNetwork.trim_uuid(params[:dc_network])) if params[:dc_network]

    ds = datetime_range_params_filter(:networks__created, ds)
    ds = datetime_range_params_filter(:networks__deleted, ds)

    if params[:service_type]
      validate_service_type(params[:service_type])
      ds = ds.filter(:networks__service_type=>params[:service_type])
    end

    if params[:dc_network]
      dc_network_id = M::DcNetwork
    end

    collection_respond_with(ds) do |paging_ds|
      R::NetworkCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    # description "Retrieve details about a network"
    # params :id required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?

    respond_with(R::Network.new(nw).generate)
  end

  post do
    # description "Create new network"
    # params :gw required default gateway address of the network
    # params :network required network address of the network
    # params :prefix optional  netmask bit length. it will be
    #               set 24 if none.
    # params :description optional description for the network
    # params :display_name optional

    dc_network = M::DcNetwork.find(:uuid => M::DcNetwork.trim_uuid(params[:dc_network]))

    raise E::UnknownDcNetwork,      params[:dc_network] unless dc_network
    raise E::DcNetworkNotPermitted, params[:dc_network] unless dc_network.allow_new_networks
    raise E::DcNetworkNotPermitted, params[:dc_network] unless dc_network.offering_network_modes.index(params[:network_mode])

    savedata = {
      :account_id=>@account.canonical_uuid,
      :ipv4_network => params[:network],
      :prefix => params[:prefix].to_i,
      :network_mode => params[:network_mode],
    }

    if params[:service_type]
      validate_service_type(params[:service_type])
      savedata[:service_type] = params[:service_type]
    end

    savedata[:display_name] = params[:display_name] if params[:display_name]
    savedata[:description] = params[:description] if params[:description]
    savedata[:domain_name] = params[:domain_name] if params[:domain_name]
    savedata[:ipv4_gw] = params[:gw] if params[:gw]
    savedata[:ip_assignment] = params[:ip_assignment] if params[:ip_assignment]
    savedata[:editable] = params[:editable] if params[:editable]

    network_address = IPAddress::IPv4.new("#{savedata[:ipv4_network]}/#{savedata[:prefix]}")
    network_services = []

    raise E::NetworkInvalidAddress if network_address.nil?

    if params[:service_dhcp]
      network_services << {
        :name => 'dhcp',
        :incoming_port => 67,
        :outgoing_port => 68,
        :ipv4 => get_service_address(network_address, params[:service_dhcp]),
      }
    end

    if params[:service_dns]
      network_services << {
        :name => 'dns',
        :incoming_port => 53,
        :ipv4 => get_service_address(network_address, params[:service_dns]),
      }
    end

    if params[:service_gateway]
      network_services << {
        :name => 'gateway',
        :ipv4 => get_service_address(network_address, params[:service_gateway]),
      }
    end

    nw = M::Network.create(savedata)
    nw.dc_network = dc_network
    nw.save

    network_services.each { |service|
      if service[:ipv4]
        service[:network_vif_id] = nw.add_service_vif(service[:ipv4]).id
        service.delete(:ipv4)
      end

      M::NetworkService.create(service)
    }

    if params[:dhcp_range] == "default"
      nw.add_ipv4_dynamic_range(network_address.first, network_address.last)
    end

    respond_with(R::Network.new(nw).generate)
  end

  delete '/:id' do
    # description "Remove network information"
    # params :id required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    nw.destroy

    respond_with([nw.canonical_uuid])
  end

  get '/:id/dhcp_ranges' do
    # description 'Register reserved IP address to the network'
    # params id, string, required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?

    respond_with(R::DhcpRangeCollection.new(nw.dhcp_range_dataset).generate)
  end

  put '/:id/dhcp_ranges/add' do
    # description 'Register reserved IP address to the network'
    # params id, string, required
    # params range_begin, string, required
    # params range_end, string, required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    raise E::NetworkNotPermitted, params[:id] if !nw.editable

    nw.add_ipv4_dynamic_range(params[:range_begin], params[:range_end])
    respond_with({})
  end

  put '/:id/dhcp_ranges/remove' do
    # description 'Register reserved IP address to the network'
    # params id, string, required
    # params range_begin, string, required
    # params range_end, string, required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    raise E::NetworkNotPermitted, params[:id] if !nw.editable

    nw.del_ipv4_dynamic_range(params[:range_begin], params[:range_end])
    respond_with({})
  end

  put '/:id/dhcp/reserve' do
    # description 'Register reserved IP address to the network'
    # params id, string, required
    # params ipaddr, [String,Array], required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?

    (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
      nw.network_vif_ip_lease_dataset.add_reserved(ip)
    }
    respond_with({})
  end

  put '/:id/dhcp/release' do
    # description 'Unregister reserved IP address from the network'
    # params id, string, required
    # params ipaddr, [String,Array], required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?

    (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
      nw.network_vif_ip_lease_dataset.delete_reserved(ip)
    }
    respond_with({})
  end

  get '/:id/vifs' do
    # description 'List vifs on this network'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    ds = nw.network_vif_dataset

    collection_respond_with(ds) do |paging_ds|
      R::NetworkVifCollection.new(paging_ds).generate
    end
  end

  get '/:id/vifs/:vif_id' do
    # description "Retrieve details about a vif"
    # params id, string, required
    # params vif_id, string, required

    # Find a better way to convert to canonical network uuid.
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    vif = find_by_uuid(M::NetworkVif, params[:vif_id])
    raise E::UnknownNetworkVif, params[:vif_id] if vif.nil?

    # Compare nw.id and vif.network_id.

    respond_with(R::NetworkVif.new(vif).generate)
  end

  post '/:id/vifs' do
    # description "Create new network vif"
    # params id, string, required
    nw = find_by_uuid(M::Network, params[:id])

    savedata = {
      :network_id => nw.id
    }
    vif = M::NetworkVif.create(savedata)

    respond_with(R::NetworkVif.new(vif).generate)
  end

  delete '/:id/vifs/:vif_id' do
    # description 'Delete a vif on this network'
    # params id, string, required
    # params vif_id, string, required
    M::NetworkVif.lock!
    nw = find_by_uuid(M::Network, params[:id])

    vif = nw.network_vif.detect { |itr| itr.canonical_uuid == params[:vif_id] }
    raise(UnknownNetworkVif) if vif.nil?

    vif.destroy
    respond_with({})
  end

  put '/:id/vifs/:vif_id/attach' do
    # description 'Attach a vif to this vif'
    # params id, string, required
    # params vif_id, string, required
    M::NetworkVif.lock!
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    vif = find_by_uuid(M::NetworkVif, params[:vif_id])
    raise(E::NetworkVifNicNotFound, params[:vif_id]) if vif.nil?
    raise(E::NetworkVifAlreadyAttached) unless vif.network.nil?

    # Check that the vif belongs to network?

    instance = vif.instance
    vif.attach_to_network(nw)

    # Find better way of figuring out when an instance is not running.
    if instance.host_node
      on_after_commit do
        Dcmgr.messaging.submit("hva-handle.#{instance.host_node.node_id}", 'attach_nic',
                               nw.dc_network.name, vif.canonical_uuid)
      end
    end

    respond_with(R::NetworkVif.new(vif).generate)
  end

  put '/:id/vifs/:vif_id/detach' do
    # description 'Detach a vif to this vif'
    # params id, string, required
    # params vif_id, string, required
    M::NetworkVif.lock!
    nw = find_by_uuid(M::Network, params[:id])
    raise(E::UnknownNetwork, params[:id]) if nw.nil?
    vif = find_by_uuid(M::NetworkVif, params[:vif_id])
    raise(E::UnknownNetworkVif, params[:vif_id]) if vif.nil?
    # Verify the network id.
    raise(E::NetworkVifNotAttached) if vif.network_id.nil? or vif.network_id != nw.id

    instance = vif.instance
    vif.detach_from_network

    # Find better way of figuring out when an instance is not running.
    if instance.host_node
      on_after_commit do
        Dcmgr.messaging.submit("hva-handle.#{instance.host_node.node_id}", 'detach_nic',
                               nw.dc_network.name, vif.canonical_uuid)
      end
    end

    respond_with(R::NetworkVif.new(vif).generate)
  end

  get '/:id/services' do
    # description 'List services on this network'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    ds = nw.network_service

    collection_respond_with(ds) do |paging_ds|
      R::NetworkServiceCollection.new(paging_ds).generate
    end
  end

  post '/:id/services' do
    # description 'Register new service on the network'
    # params id, string, required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    raise E::NetworkNotPermitted, params[:id] if !nw.editable

    service_data = {
      :name => params[:name],
      :incoming_port => params[:incoming_port],
      :outgoing_port => params[:outgoing_port],
      :network_vif_id => nw.add_service_vif(params[:ipv4]).id
    }

    service = M::NetworkService.create(service_data)

    on_after_commit do
      Dcmgr.messaging.event_publish("vnet/network_services",
                                    :args => {
                                      :status => :add,
                                      :service => service.to_hash,
                                    })
    end

    respond_with(R::NetworkService.new(service).generate)
  end

  delete '/:id/services' do
    # description 'Delete a vif on this network'
    # params id, string, required
    # params vif_id, string, required
    # params name, string, required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    raise E::NetworkNotPermitted, params[:id] if !nw.editable

    service = nw.network_service(:name => params[:name]).detect { |itr| itr.network_vif.canonical_uuid == params[:vif_id] }
    raise(UnknownNetworkService) if service.nil?

    on_after_commit do
      Dcmgr.messaging.event_publish("vnet/network_services",
                                    :args => {
                                      :status => :delete,
                                      :service => service.to_hash,
                                    })
    end

    service.destroy
    respond_with({})
  end

  get '/:id/routes' do
    # description 'List services on this network'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?

    filter = {:network_vif_ip_leases__network_id => nw.id}
    filter[:network_routes__route_type] = params[:route_type] if params[:route_type]

    ds = M::NetworkRoute.dataset.where_with_ip_leases(filter)

    collection_respond_with(ds) do |paging_ds|
      R::NetworkRouteCollection.new(paging_ds).generate
    end
  end

  # # Make GRE tunnels, currently used for testing purposes.
  # post '/:id/tunnels' do
  #   # description 'Create a tunnel on this network'
  #   # params id required
  #   # params dest_id required
  #   # params dest_ip required
  #   # params tunnel_id required
  #   nw = find_by_uuid(M::Network, params[:id])

  #   tunnel_name = "gre-#{params[:dest_id]}-#{params[:tunnel_id]}"
  #   command = "/usr/share/axsh/wakame-vdc/ovs/bin/ovs-vsctl add-port br0 #{tunnel_name} -- set interface #{tunnel_name} type=gre options:remote_ip=#{params[:dest_ip]} options:key=#{params[:tunnel_id]}"

  #   system(command)
  #   respond_with({})
  # end

  # delete '/:id/tunnels/:tunnel_id' do
  #   # description 'Destroy a tunnel on this network'
  #   # params :id required
  #   # params :tunnel_id required
  #   nw = find_by_uuid(M::Network, params[:id])

  #   tunnel_name = "gre-#{params[:dest_id]}-#{params[:tunnel_id]}"

  #   system("/usr/share/axsh/wakame-vdc/ovs/bin/ovs-vsctl del-port br0 #{tunnel_name}")
  #   respond_with({})
  # end

  put '/:id' do
    # description
    # param :id, string, :required
    # param :display_name , string, :optional
    raise E::UndefinedNetworkID if params[:id].nil?
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork if nw.nil?

    nw.display_name = params[:display_name] if params[:display_name]
    nw.save_changes

    respond_with(R::Network.new(nw).generate)
  end
end
