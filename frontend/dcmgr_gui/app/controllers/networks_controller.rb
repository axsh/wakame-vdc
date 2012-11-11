class NetworksController < ApplicationController
  respond_to :json
  include Util
  
  def index
  end
  
  def create
    catch_error do
      data = {
        :display_name => params[:display_name],
        :description => params[:description],
        :domain_name => params[:domain_name],
        :dc_network => params[:dc_network],
        :network_mode => params[:network_mode],
        :ipv4_network => params[:ipv4_network],
        :prefix => params[:prefix],
        :ip_assignment => params[:ip_assignment],
        :editable => 1,
      }

      data[:ipv4_gw] = params[:ipv4_gw] unless params[:ipv4_gw].to_s.empty?

      data[:service_dhcp] = params[:service_dhcp] if params[:service_dhcp]
      data[:service_dns] = params[:service_dns] if params[:service_dns]
      data[:service_gateway] = params[:service_gateway] if params[:service_gateway]

      data[:dhcp_range] = "default" if params[:service_dhcp_use_default]

      @network = Hijiki::DcmgrResource::Network.create(data)
      render :json => @network
    end
  end

  def destroy
  end
  
  def list
    catch_error do
      data = {
        :start => params[:start].to_i - 1,
        :limit => params[:limit]
      }
      networks = Hijiki::DcmgrResource::Network.list(data)
      respond_with(networks[0],:to => [:json])
    end
  end
  
  # GET networks/nw-24f1af4d.json
  def show
    catch_error do
      network_id = params[:id]
      detail = Hijiki::DcmgrResource::Network.show(network_id)
      respond_with(detail,:to => [:json])
    end
  end

  def attach
    detail = Hijiki::DcmgrResource::Network.find(params[:network_id]).attach(params[:vif_id])
    render :json => detail
  end

  def detach
    detail = Hijiki::DcmgrResource::Network.find(params[:network_id]).detach(params[:vif_id])
    render :json => detail
  end
  
  def show_networks
    catch_error do
      @network = Hijiki::DcmgrResource::Network.list
      respond_with(@network[0],:to => [:json])
    end
  end

  def show_dhcp_ranges
    catch_error do
      network_id = params[:id]
      detail = Hijiki::DcmgrResource::Network.find(network_id).get_dhcp_ranges
      respond_with(detail,:to => [:json])
    end
  end

  def add_dhcp_range
    catch_error do
      network_id = params[:id]
      detail = Hijiki::DcmgrResource::Network.find(network_id).add_dhcp_range(params[:range_begin], params[:range_end])
      respond_with(detail,:to => [:json])
    end
  end

  def remove_dhcp_range
    catch_error do
      network_id = params[:id]
      detail = Hijiki::DcmgrResource::Network.find(network_id).remove_dhcp_range(params[:range_begin], params[:range_end])
      respond_with(detail,:to => [:json])
    end
  end

  def show_services
    catch_error do
      network_id = params[:id]
      detail = Hijiki::DcmgrResource::NetworkService.list(:network_id => network_id)
      respond_with(detail,:to => [:json])
    end
  end

  def create_service
    catch_error do
      data = {
        :name => params[:name],
        :ipv4 => params[:ipv4],
        :incoming_port => params[:incoming_port],
        :outgoing_port => params[:outgoing_port],
      }
      service = Hijiki::DcmgrResource::NetworkService.create(params[:id], data)
      render :json => service
    end
  end

  def delete_service
    catch_error do
      service = Hijiki::DcmgrResource::Network.find(params[:id]).delete_service(params[:vif_id], params[:name])
      render :json => service
    end
  end

  def total
    catch_error do
      all_resource_count = Hijiki::DcmgrResource::Network.total_resource
      all_resources = Hijiki::DcmgrResource::Network.find(:all,:params => {:start => 0, :limit => all_resource_count})
      resources = all_resources[0].results
      # deleted_resource_count = Hijiki::DcmgrResource::Network.get_resource_state_count(resources, 'deleted')
      total = all_resource_count # - deleted_resource_count
      render :json => total
    end
  end
end
