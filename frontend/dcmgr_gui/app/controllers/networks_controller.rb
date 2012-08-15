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
        :ipv4_gw => params[:ipv4_gw],
        :prefix => params[:prefix],
        :ip_assignment => params[:ip_assignment],
      }
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
  
  # GET networks/vol-24f1af4d.json
  def show
    catch_error do
      network_id = params[:id]
      detail = Hijiki::DcmgrResource::Network.show(network_id)
      respond_with(detail,:to => [:json])
    end
  end

  def attach
    detail = Hijiki::DcmgrResource::NetworkVif.find_vif(params[:network_id], params[:vif_id]).attach
    render :json => detail
  end

  def detach
    detail = Hijiki::DcmgrResource::NetworkVif.find_vif(params[:network_id], params[:vif_id]).detach
    render :json => detail
  end
  
  def show_networks
    catch_error do
      @network = Hijiki::DcmgrResource::Network.list
      respond_with(@network[0],:to => [:json])
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
