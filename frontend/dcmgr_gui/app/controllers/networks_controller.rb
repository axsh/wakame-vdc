class NetworksController < ApplicationController
  respond_to :json
  include Util
  
  def index
  end
  
  def create
    # snapshot_ids = params[:ids]
    # if snapshot_ids
    #   res = []
    #   snapshot_ids.each do |snapshot_id|
    #     data = {
    #       :snapshot_id => snapshot_id
    #     }
    #     res << DcmgrResource::Network.create(data)
    #   end
    #   render :json => res
    # else
    #   # Convert to MB
    #   size = case params[:unit]
    #          when 'gb'
    #            params[:size].to_i * 1024
    #          when 'tb'
    #            params[:size].to_i * 1024 * 1024
    #          end
      
    #   storage_node_id = params[:storage_node_id] #option
      
    #   data = {
    #     :network_size => size,
    #     :storage_node_id => storage_node_id
    #   }
      
    #   @network = DcmgrResource::Network.create(data)

    #   render :json => @network
    # end
  end
  
  def destroy
    # network_ids = params[:ids]
    # res = []
    # network_ids.each do |network_id|
    #   res << DcmgrResource::Network.destroy(network_id)
    # end
    # render :json => res
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    networks = DcmgrResource::Network.list(data)
    respond_with(networks[0],:to => [:json])
  end
  
  # GET networks/vol-24f1af4d.json
  def show
    network_id = params[:id]
    detail = DcmgrResource::Network.show(network_id)
    respond_with(detail,:to => [:json])
  end

  def attach
    # instance_id = params[:instance_id]
    # network_ids = params[:network_ids]
    # res = []
    # network_ids.each do |network_id|
    #   data = {
    #     :network_id => network_id
    #   }
    #   res << DcmgrResource::Network.attach(network_id, instance_id)
    # end
    # render :json => res
  end

  def detach
    # network_ids = params[:ids]
    # res = []
    # network_ids.each do |network_id|
    #   res << DcmgrResource::Network.detach(network_id)
    # end
    # render :json => res
  end
  
  def total
    all_resource_count = DcmgrResource::Network.total_resource
    all_resources = DcmgrResource::Network.find(:all,:params => {:start => 0, :limit => all_resource_count})
    resources = all_resources[0].results
    # deleted_resource_count = DcmgrResource::Network.get_resource_state_count(resources, 'deleted')
    total = all_resource_count # - deleted_resource_count
    render :json => total
  end
end
