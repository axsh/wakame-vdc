class HostPoolsController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    host_pools = DcmgrResource::HostPool.list(data)
    respond_with(host_pools[0], :to => [:json])
  end
  
  def show
    host_pool_id = params[:id]
    detail = DcmgrResource::HostPool.show(host_pool_id)
    respond_with(detail,:to => [:json])
  end
  
  def show_host_pools
    host_pools = DcmgrResource::HostPool.list
    respond_with(host_pools[0],:to => [:json])
  end
end
